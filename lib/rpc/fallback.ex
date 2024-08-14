defmodule Split.RPC.Fallback do
  alias Split.RPC.Message
  use Split.RPC.Opcodes
  alias Split.Treatment

  def fallback(%Message{o: opcode})
      when opcode in [@get_treatment_opcode, @get_treatment_with_config_opcode] do
    %Treatment{}
  end

  def fallback(%Message{o: opcode})
      when opcode in [@get_treatmens_opcode, @get_treatments_with_config_opcode] do
    %{}
  end

  def fallback(%Message{o: opcode}) do
    {:error, "Unknown opcode: #{opcode}"}
  end
end
