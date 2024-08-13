defprotocol Split.RPC.Fallback do
  def fallback(message)
end

defimpl Split.RPC.Fallback, for: Split.RPC.Message do
  alias Split.RPC.Message
  alias Split.Treatment

  def fallback(%Message{o: opcode}) when opcode in [0x11, 0x13] do
    %Treatment{}
  end

  def fallback(%Message{o: opcode}) do
    {:error, "Unknown opcode: #{opcode}"}
  end
end
