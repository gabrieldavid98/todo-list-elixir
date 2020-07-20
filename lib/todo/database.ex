defmodule Todo.DataBase do
	@db_folder "./persist"

	def store(key, data) do
		:poolboy.transaction(
			__MODULE__,
			fn worker_pid -> 
				Todo.DataBaseWorker.store(worker_pid, key, data)
			end
		)
	end

	def get(key) do
		:poolboy.transaction(
			__MODULE__,
			fn worker_pid ->
				Todo.DataBaseWorker.get(worker_pid, key)
			end
		)
	end

	def child_spec(_) do
		File.mkdir_p!(@db_folder)

		:poolboy.child_spec(
			__MODULE__,
			[
				name: {:local, __MODULE__},
				worker_module: Todo.DataBaseWorker,
				size: 3,
			],
			[@db_folder]
		)
	end
end
