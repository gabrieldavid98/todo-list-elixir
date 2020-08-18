use Mix.Config

config :todo_list, http_port: 5454

import_config "#{Mix.env()}.exs"
