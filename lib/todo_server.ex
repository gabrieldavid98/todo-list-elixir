defmodule TodoServer do
	def start do
		pid = ServerProcess.start(__MODULE__)
		Process.register(pid, :todo_server)
	end

	def init do
		TodoList.new()
	end

	def entries(date),
		do: ServerProcess.call(:todo_server, {:entries, date})

	def add_entry(new_entry),
		do: ServerProcess.cast(:todo_server, {:add_entry, new_entry})

	def update_entry(updated_entry),
		do: ServerProcess.cast(:todo_server, {:update_entry, updated_entry})

	def delete_entry(entry_id),
		do: ServerProcess.cast(:todo_server, {:delete_entry, entry_id})

	def handle_call({:entries, date}, todo_list) do
		entries = TodoList.entries(todo_list, date)
		{entries, todo_list}
	end

	def handle_call(_, todo_list), do: {:ok, todo_list}

	def handle_cast({:add_entry, new_entry}, todo_list) do
		TodoList.add_entry(todo_list, new_entry)
	end

	def handle_cast({:update_entry, updated_entry}, todo_list) do
		TodoList.update_entry(todo_list, updated_entry)
	end

	def handle_cast({:delete_entry, entry_id}, todo_list) do
		TodoList.delete_entry(todo_list, entry_id)
	end

	def handle_cast(_, todo_list), do: todo_list
end

defmodule ServerProcess do
	def start(callback_module) do
		spawn(fn ->
			initial_state = callback_module.init()
			loop(callback_module, initial_state)
		end)
	end

	def cast(server_pid, request) do
		send(server_pid, {:cast, request})
	end

	def call(server_pid, request) do
		send(server_pid, {:call, request, self()})
		receive do
			{:response, response} -> response
		end
	end

	defp loop(callback_module, current_state) do
		receive do
			{:call, request, caller} ->
				{response, new_state} =
					callback_module.handle_call(
						request,
						current_state
					)

				send(caller, {:response, response})
				loop(callback_module, new_state)
			{:cast, request} ->
				new_state = callback_module.handle_cast(
					request,
					current_state
				)

				loop(callback_module, new_state)
		end
	end
end
