defmodule Split.RPC.Encoder do
  @moduledoc """
  Encoder module for Splitd.
  """
  alias Split.RPC.Message

  @doc """
  Encodes an RPC message using Msgpax and appends the size of the encoded message in bytes.

  ## Examples

      iex> message = Split.RPC.Message.split("test_split")
      iex> [size, encoded] = Split.RPC.Encoder.encode(message)
      iex> size == <<byte_size(encoded)::integer-unsigned-little-size(32)>>
      iex> Msgpax.unpack!(encoded)

      %{"a" => ["test_split"], "o" => 161, "v" => 1}
  """
  @spec encode(Message.t()) :: iodata()
  def encode(message) do
    encoded = Msgpax.pack!(message, iodata: false)

    [<<byte_size(encoded)::integer-unsigned-little-size(32)>>, encoded]
  end
end
