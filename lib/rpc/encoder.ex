defmodule Split.RPC.Encoder do
  @moduledoc """
  Encoder module for Splitd.
  """
  alias Split.RPC.Message

  @doc """
  Encodes an RPC message using Msgpax and appends the size of the encoded message in bytes.

  ## Examples

      iex> Split.RPC.Encoder.encode(%Split.RPC.Message{v: 1, o: 0xA1, a: ["split_name"]})
      [
        <<22, 0, 0, 0>>,
        <<131, 161, 111, 204, 161, 161, 97, 145, 170, 115, 112, 108, 105, 116, 95, 110, 97, 109, 101, 161, 118, 1>>
      ]
  """
  @spec encode(Message.t()) :: iodata()
  def encode(message) do
    encoded = Msgpax.pack!(message, iodata: false)

    [<<byte_size(encoded)::integer-unsigned-little-size(32)>>, encoded]
  end
end
