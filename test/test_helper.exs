File.rm("/tmp/elixir-splitd.sock")
Split.Test.MockSplitdServer.start_link([])
ExUnit.start()
