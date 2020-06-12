defmodule Todo.DataBase do
	use GenServer

	@db_folder "./persist"

	def start_link(_) do
		IO.puts("Starting database server")
		GenServer.start_link(__MODULE__, nil, name: __MODULE__)
	end

	def store(key, data) do
		key
		|> choose_worker()
		|> Todo.DataBaseWorker.store(key, data)
	end

	def get(key) do
		key
		|> choose_worker()
		|> Todo.DataBaseWorker.get(key)
	end

	@impl GenServer
	def init(_) do
		File.mkdir_p!(@db_folder)

		{:ok, start_workers()}
	end

	@impl GenServer
	def handle_call({:choose_worker, key}, _, workers) do
		worker_key = :erlang.phash2(key, 3)
		{:reply, Map.get(workers, worker_key), workers}
	end

	defp start_workers do
		for index <- 1..3, into: %{} do
			{:ok, pid} = Todo.DataBaseWorker.start_link(@db_folder)
			{index - 1, pid}
		end
	end

	defp choose_worker(key) do
		GenServer.call(__MODULE__, {:choose_worker, key})
	end
end
