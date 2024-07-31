File.rm("/tmp/elixir-splitd.sock")
Split.Test.MockSplitdServer.start_link([])
Mimic.copy(Split.Sockets.Pool)
ExUnit.start()
