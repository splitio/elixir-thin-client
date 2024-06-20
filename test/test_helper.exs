File.rm("/tmp/elixir-splitd.sock")
Cachex.start_link(name: :split_sdk_cache)
Split.Test.Server.start_link(nil)
ExUnit.start()
