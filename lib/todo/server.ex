defmodule Todo.Server do
	use GenServer

	def start do
		GenServer.start(__MODULE__, nil)
	end

	@impl GenServer
	def init(_) do
		{:ok, Todo.List.new()}
	end

	def entries(todo_server, date),
		do: GenServer.call(todo_server, {:entries, date})

	def add_entry(todo_server, new_entry),
		do: GenServer.cast(todo_server, {:add_entry, new_entry})

	def update_entry(todo_server, updated_entry),
		do: GenServer.cast(todo_server, {:update_entry, updated_entry})

	def delete_entry(todo_server, entry_id),
		do: GenServer.cast(todo_server, {:delete_entry, entry_id})

	@impl GenServer
	def handle_call({:entries, date}, _, todo_list) do
		entries = Todo.List.entries(todo_list, date)
		{:reply, entries, todo_list}
	end

	@impl GenServer
	def handle_cast({:add_entry, new_entry}, todo_list) do
		{:noreply, Todo.List.add_entry(todo_list, new_entry)}
	end

	@impl GenServer
	def handle_cast({:update_entry, updated_entry}, todo_list) do
		{:noreply, Todo.List.update_entry(todo_list, updated_entry)}
	end

	@impl GenServer
	def handle_cast({:delete_entry, entry_id}, todo_list) do
		{:noreply, Todo.List.delete_entry(todo_list, entry_id)}
	end
end
