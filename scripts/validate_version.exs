#!/usr/bin/env elixir

# Read mix.exs version
{:ok, mix_content} = File.read("mix.exs")
version = Regex.run(~r/version: "([^"]+)"/, mix_content)
|> Enum.at(1)

# Read message.ex client_id
{:ok, message_content} = File.read("lib/split/rpc/message.ex")
client_id_version = Regex.run(~r/@client_id "Splitd_Elixir-([^"]+)"/, message_content)
|> Enum.at(1)

if version != client_id_version do
  IO.puts :stderr, """
  Error: Version mismatch!
  mix.exs version: #{version}
  message.ex @client_id version: #{client_id_version}

  Please update the @client_id in lib/split/rpc/message.ex to match the version in mix.exs
  """
  System.halt(1)
end
