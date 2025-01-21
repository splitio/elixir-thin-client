defmodule Split.RPC.Fallback do
  @moduledoc """
  This module is used to provide default values for all Splitd RPC calls.

  When a call to Splitd fails, and the SDK was initialized with `fallback_enabled`,
  the fallback values are returned instead of the error received from the socket.
  """
  use Split.RPC.Opcodes

  alias Split.RPC.Message
  alias Split.Treatment

  @doc """
  Provides a default value for the given RPC message.

  ## Examples

      iex> Fallback.fallback(%Message{o: 0x11})
      {:ok, %Treatment{treatment: "control", label: "fallback treatment"}}

      iex> Fallback.fallback(%Message{o: 0x13})
      {:ok, %Treatment{treatment: "control", label: "fallback treatment", config: nil}}

      iex> Fallback.fallback(%Message{
      ...>   o: 0x12,
      ...>   a: ["user_key", "bucketing_key", ["feature_1", "feature_2"], %{}]
      ...> })
      {:ok,
       %{
         "feature_1" => %Treatment{treatment: "control", label: "fallback treatment"},
         "feature_2" => %Treatment{treatment: "control", label: "fallback treatment"}
       }}

      iex> Fallback.fallback(%Message{o: 0x14, a: ["user_key", "bucketing_key", ["feature_a"], %{}]})
      {:ok, %{"feature_a" => %Treatment{treatment: "control", label: "fallback treatment", config: nil}}}

      iex> Fallback.fallback(%Message{o: 0xA1})
      {:ok, nil}

      iex> Fallback.fallback(%Message{o: 0xA2})
      {:ok, []}

      iex> Fallback.fallback(%Message{o: 0xA0})
      {:ok, []}

      iex> Fallback.fallback(%Message{o: 0x80})
      :ok
  """
  @spec fallback(Message.t()) :: {:ok, map() | Treatment.t(), list(), nil} | :ok
  def fallback(%Message{o: opcode})
      when opcode in [@get_treatment_opcode, @get_treatment_with_config_opcode] do
    {:ok, %Treatment{label: "fallback treatment"}}
  end

  def fallback(%Message{o: opcode, a: args})
      when opcode in [@get_treatments_opcode, @get_treatments_with_config_opcode] do
    feature_names = Enum.at(args, 2)

    treatments =
      Enum.reduce(feature_names, %{}, fn feature_name, acc ->
        Map.put(acc, feature_name, %Treatment{label: "fallback treatment"})
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
    {:ok, []}
  end

  def fallback(%Message{o: @track_opcode}) do
    :ok
  end
end
