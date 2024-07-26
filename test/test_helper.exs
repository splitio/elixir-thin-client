File.rm("/tmp/elixir-splitd.sock")
Mimic.copy(Split.Sockets.Pool)
ExUnit.start()
