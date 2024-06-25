File.rm("/tmp/elixir-splitd.sock")
Split.Test.Server.start_link(nil)
Mimic.copy(Split.Sockets.Pool)
ExUnit.start()
