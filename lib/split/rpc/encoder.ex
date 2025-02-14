defmodule Split.RPC.Encoder do
  @moduledoc """
  Encoder module for Splitd.
  """
  alias Split.RPC.Message

  @doc """
  Encodes an RPC message using Msgpax and appends the size of the encoded message in bytes.

  ## Examples

      iex> message = Message.split("test_split")
      ...> [_size, encoded] = Encoder.encode(message)
      ...> Msgpax.unpack!(encoded)
      %{"a" => ["test_split"], "o" => 161, "v" => 1}

      <!-- Encoding of get treatment arguments, including attributes -->
      iex> message = Message.get_treatment(key: %{matching_key: "user_id"}, feature_name: "test_split", attributes: %{ :foo => "bar", "baz" => 1 })
      ...> [_size, encoded] = Encoder.encode(message)
      ...> Msgpax.unpack!(encoded)
      %{"a" => ["user_id", nil, "test_split", %{"baz" => 1, "foo" => "bar"}], "o" => 17, "v" => 1}

      <!-- Encoding of track arguments, including properties -->
      iex> message = Message.track(%{matching_key: "user_id", bucketing_key: "bucket"}, "user", "purchase", 100.5, %{ "baz" => 1, foo: "bar" })
      ...> [_size, encoded] = Encoder.encode(message)
      ...> Msgpax.unpack!(encoded)
      %{"a" => ["user_id", "user", "purchase", 100.5, %{"baz" => 1, "foo" => "bar"}], "o" => 128, "v" => 1}
  """
  @spec encode(Message.t()) :: iodata()
  def encode(message) do
    encoded = Msgpax.pack!(message, iodata: false)

    [<<byte_size(encoded)::integer-unsigned-little-size(32)>>, encoded]
  end
end
