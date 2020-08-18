defmodule Todo.Server do
	use GenServer, restart: :temporary

	@expiry_idle_timeout :timer.seconds(10)

	def start_link(name) do
		IO.puts("Starting to-do server for #{name}")
		GenServer.start_link(__MODULE__, name, name: global_name(name))
	end

	@impl GenServer
	def init(name) do
		{
			:ok, 
			{name, Todo.DataBase.get(name) || Todo.List.new()},
			@expiry_idle_timeout
		}
	end

	def entries(todo_server, date),
		do: GenServer.call(todo_server, {:entries, date})

	def add_entry(todo_server, new_entry),
		do: GenServer.cast(todo_server, {:add_entry, new_entry})

	def update_entry(todo_server, updated_entry),
		do: GenServer.cast(todo_server, {:update_entry, updated_entry})

	def delete_entry(todo_server, entry_id),
		do: GenServer.cast(todo_server, {:delete_entry, entry_id})

	def whereis(name) do
		case :global.whereis_name({__MODULE__, name}) do
			:undefined -> nil
			pid -> pid
		end
	end

	@impl GenServer
	def handle_call({:entries, date}, _, {name, todo_list}) do
		entries = Todo.List.entries(todo_list, date)
		{:reply, entries, {name, todo_list}, @expiry_idle_timeout}
	end

	@impl GenServer
	def handle_cast({:add_entry, new_entry}, {name, todo_list}) do
		new_list = Todo.List.add_entry(todo_list, new_entry)
		Todo.DataBase.store(name, new_list)
		{:noreply, {name, new_list}, @expiry_idle_timeout}
	end

	@impl GenServer
	def handle_cast({:update_entry, updated_entry}, {name, todo_list}) do
		updated_list = Todo.List.update_entry(todo_list, updated_entry)
		{:noreply, {name, updated_list}, @expiry_idle_timeout}
	end

	@impl GenServer
	def handle_cast({:delete_entry, entry_id}, {name, todo_list}) do
		new_list = Todo.List.delete_entry(todo_list, entry_id)
		{:noreply, {name, new_list}, @expiry_idle_timeout}
	end

	@impl GenServer
	def handle_info(:timeout, {name, todo_list}) do
		IO.puts("Stopping to-do server for #{name}")
		{:stop, :normal, {name, todo_list}}
	end

	defp global_name(name), do: {:global, {__MODULE__, name}}
end
