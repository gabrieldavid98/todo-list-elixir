defmodule Todo.DataBase do
	@pool_size 3
	@db_folder "./persist"

	def start_link do
		File.mkdir_p!(@db_folder)

		children = Enum.map(1..@pool_size, &worker_spec/1)
		Supervisor.start_link(children, strategy: :one_for_one)
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

	def child_spec(_) do
		%{
			id: __MODULE__,
			start: {__MODULE__, :start_link, []},
			type: :supervisor
		}
	end

	defp choose_worker(key) do
		:erlang.phash2(key, @pool_size) + 1
	end

	defp worker_spec(worker_id) do
		default_worker_spec = {Todo.DataBaseWorker, {@db_folder, worker_id}}
		Supervisor.child_spec(default_worker_spec, id: worker_id)
	end
end
