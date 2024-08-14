defmodule Split.RPC.Fallback do
  @moduledoc """
  This module is used to provide default values for all Splitd RPC calls.

  When a call to Splitd fails, and the SDK was initialized  with `fallback_enabled`,
  the fallback values are returned instead of the error received from the socket.
  """
  use Split.RPC.Opcodes

  alias Split.RPC.Message
  alias Split.Treatment

  def fallback(%Message{o: opcode})
      when opcode in [@get_treatment_opcode, @get_treatment_with_config_opcode] do
    {:ok, %Treatment{}}
  end

  def fallback(%Message{o: opcode, a: args})
      when opcode in [@get_treatments_opcode, @get_treatments_with_config_opcode] do
    feature_names = Enum.at(args, 2)

    treatments =
      Enum.reduce(feature_names, %{}, fn feature_name, acc ->
        Map.put(acc, feature_name, %Treatment{})
      end)

    {:ok, treatments}
  end

  def fallback(%Message{o: @split_opcode}) do
    {:ok, nil}
  end

  def fallback(%Message{o: @splits_opcode}) do
    {:ok, []}
  end

  def fallback(%Message{o: @split_names_opcode}) do
    {:ok, %{split_names: []}}
  end

  def fallback(%Message{o: @track_opcode}) do
    :ok
  end

  def fallback(%Message{o: opcode}) do
    {:error, "Unknown opcode: #{opcode}"}
  end
end
