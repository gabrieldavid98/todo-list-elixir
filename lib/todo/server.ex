defmodule Todo.Server do
	use GenServer

	def start do
		GenServer.start(__MODULE__, nil, name: __MODULE__)
	end

	@impl GenServer
	def init(_) do
		{:ok, Todo.List.new()}
	end

	def entries(date),
		do: GenServer.call(__MODULE__, {:entries, date})

	def add_entry(new_entry),
		do: GenServer.cast(__MODULE__, {:add_entry, new_entry})

	def update_entry(updated_entry),
		do: GenServer.cast(__MODULE__, {:update_entry, updated_entry})

	def delete_entry(entry_id),
		do: GenServer.cast(__MODULE__, {:delete_entry, entry_id})

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
