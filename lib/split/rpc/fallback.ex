defmodule Split.RPC.Fallback do
  @moduledoc """
  This module is used to provide default values for all Splitd RPC calls.

  When a call to Splitd fails, the fallback values are returned instead of the error received from the socket.
  """
  use Split.RPC.Opcodes

  alias Split.RPC.Message
  alias Split.Impression

  @doc """
  Provides a default value for the given RPC message.

  ## Examples

      iex> Fallback.fallback(%Message{o: 0x11})
      %Impression{treatment: "control", label: "exception"}

      iex> Fallback.fallback(%Message{o: 0x13})
      %Impression{treatment: "control", label: "exception", config: nil}

      iex> Fallback.fallback(%Message{
      ...>   o: 0x12,
      ...>   a: ["user_key", "bucketing_key", ["feature_1", "feature_2"], %{}]
      ...> })
      %{
        "feature_1" => %Impression{treatment: "control", label: "exception"},
        "feature_2" => %Impression{treatment: "control", label: "exception"}
      }

      iex> Fallback.fallback(%Message{o: 0x14, a: ["user_key", "bucketing_key", ["feature_a"], %{}]})
      %{"feature_a" => %Impression{treatment: "control", label: "exception", config: nil}}

      iex> Fallback.fallback(%Message{o: 0xA1})
      nil

      iex> Fallback.fallback(%Message{o: 0xA2})
      []

      iex> Fallback.fallback(%Message{o: 0xA0})
      []

      iex> Fallback.fallback(%Message{o: 0x80})
      false
  """
  @spec fallback(Message.t()) :: map() | Impression.t() | list() | boolean() | nil
  def fallback(%Message{o: opcode})
      when opcode in [@get_treatment_opcode, @get_treatment_with_config_opcode] do
    %Impression{label: "exception"}
  end

  def fallback(%Message{o: opcode, a: args})
      when opcode in [@get_treatments_opcode, @get_treatments_with_config_opcode] do
    feature_names = Enum.at(args, 2)

    treatments =
      Enum.reduce(feature_names, %{}, fn feature_name, acc ->
        Map.put(acc, feature_name, %Impression{label: "exception"})
      end)

    treatments
  end

  def fallback(%Message{o: opcode, a: _})
      when opcode in [
             @get_treatments_by_flag_set_opcode,
             @get_treatments_with_config_by_flag_set_opcode,
             @get_treatments_by_flag_sets_opcode,
             @get_treatments_with_config_by_flag_sets_opcode
           ] do
    # Empty map since we don't have a way to know the feature names
    %{}
  end

  def fallback(%Message{o: @split_opcode}) do
    nil
  end

  def fallback(%Message{o: @splits_opcode}) do
    []
  end

  def fallback(%Message{o: @split_names_opcode}) do
    []
  end

  def fallback(%Message{o: @track_opcode}) do
    false
  end
end
