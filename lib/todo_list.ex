defmodule TodoServer do
	def start do
		pid = spawn(fn -> loop(TodoList.new()) end)
		Process.register(pid, :todo_server)
	end

	def entries(date) do
		send(:todo_server, {:entries, self(), date})
		receive do
			{:entries, entries} -> entries
		after
			5000 -> {:error, :timeout}
		end
	end

	def add_entry(new_entry),
		do: send(:todo_server, {:add_entry, new_entry})

	def update_entry(updated_entry),
		do: send(:todo_server, {:update_entry, updated_entry})

	def delete_entry(entry_id),
		do: send(:todo_server, {:delete_entry, entry_id})

	defp loop(todo_list) do
		new_todo_list =
			receive do
				msg -> process_message(todo_list, msg)
			end

		loop(new_todo_list)
	end

	defp process_message(todo_list, {:entries, caller, date}) do
		entries = TodoList.entries(todo_list, date)
		send(caller, {:entries, entries})
		todo_list
	end

	defp process_message(todo_list, {:add_entry, new_entry}) do
		TodoList.add_entry(todo_list, new_entry)
	end

	defp process_message(todo_list, {:update_entry, updated_entry}) do
		TodoList.update_entry(todo_list, updated_entry)
	end

	defp process_message(todo_list, {:delete_entry, entry_id}) do
		TodoList.delete_entry(todo_list, entry_id)
	end

	defp process_message(todo_list, _), do: todo_list
end

defmodule TodoList do
	defstruct auto_id: 1, entries: %{}

	def new(entries \\ []) do
		Enum.reduce(
			entries,
			%TodoList{},
			&add_entry(&2, &1)
		)
	end

	# def new(), do: %TodoList{}

	def add_entry(todo_list, entry) do
		entry = Map.put(entry, :id, todo_list.auto_id)

		new_entries = Map.put(todo_list.entries, todo_list.auto_id, entry)

		%TodoList{
			todo_list |
			entries: new_entries,
			auto_id: todo_list.auto_id + 1
		}
	end

	def entries(todo_list, date) do
		todo_list.entries
		|> Stream.filter(fn {_, entry} -> entry.date == date end)
		|> Enum.map(fn {_, entry} -> entry end)
	end

	def update_entry(todo_list, %{} = new_entry) do
		update_entry(todo_list, new_entry.id, fn _ -> new_entry end)
	end

	def update_entry(todo_list, entry_id, updater_fun) do
		case Map.fetch(todo_list.entries, entry_id) do
			:error -> todo_list
			{:ok, old_entry} ->
				old_entry_id = old_entry.id
				new_entry = %{id: ^old_entry_id} = updater_fun.(old_entry)
				new_entries = Map.put(todo_list.entries, new_entry.id, new_entry)
				%TodoList{todo_list | entries: new_entries}
		end
	end

	def delete_entry(todo_list, entry_id) do
		%TodoList{
			todo_list |
			entries: Map.delete(todo_list.entries, entry_id)
		}
	end
end

defmodule TodoList.CsvImporter do
	def import(file_name) do
		file_name
		|> read_lines()
		|> create_entries()
		|> TodoList.new()
	end

	defp read_lines(file_name) do
		file_name
		|> File.stream!()
		|> Stream.map(&String.replace(&1, "\n", ""))
	end

	defp create_entries(lines) do
		lines
		|> Stream.map(&extract_fields/1)
		|> Stream.map(&create_entry/1)
	end

	defp extract_fields(line) do
		line
		|> String.split(",")
		|> convert_date()
	end

	defp convert_date([date_string, title]) do
		{parse_date(date_string), title}
	end

	defp parse_date(date_string) do
		[year, month, day] =
			date_string
			|> String.split("/")
			|> Enum.map(&String.to_integer/1)

		{:ok, date} = Date.new(year, month, day)
		date
	end

	defp create_entry({date, title}) do
		%{date: date, title: title}
	end
end

defimpl Collectable, for: TodoList do
	def into(original) do
		{original, &into_callback/2}
	end

	defp into_callback(todo_list, {:cont, entry}) do
		TodoList.add_entry(todo_list, entry)
	end

	defp into_callback(todo_list, :done), do: todo_list
	defp into_callback(_, :halt), do: :ok
end
