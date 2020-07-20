defmodule Todo.System do
	def start_link do
		Supervisor.start_link(
			[
				Todo.ProcessRegistry,
				Todo.DataBase, 
				Todo.Cache,
				Todo.Web,
			], 
			strategy: :one_for_one
		)
	end
end
