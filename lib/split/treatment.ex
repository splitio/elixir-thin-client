defmodule Split.Treatment do
  defstruct treatment: "control",
            label: nil,
            config: nil,
            change_number: nil,
            timestamp: nil

  @type t :: %__MODULE__{
          treatment: String.t(),
          label: String.t() | nil,
          config: String.t() | nil,
          change_number: integer() | nil,
          timestamp: integer() | nil
        }

  @spec build_from_daemon_response(map()) :: t
  def build_from_daemon_response(treatment_payload) do
    treatment = treatment_payload["t"]
    config = treatment_payload["c"]
    label = get_in(treatment_payload, ["l", "l"])
    change_number = get_in(treatment_payload, ["l", "c"])
    timestamp = get_in(treatment_payload, ["l", "m"])

    %Split.Treatment{
      treatment: treatment,
      label: label,
      config: config,
      change_number: change_number,
      timestamp: timestamp
    }
  end

  @spec map_to_treatment_with_config(t()) :: Split.TreatmentWithConfig.t()
  def map_to_treatment_with_config(treatment) do
    %Split.TreatmentWithConfig{
      treatment: treatment.treatment,
      config: treatment.config
    }
  end

  @spec map_to_treatment_string(t()) :: String.t()
  def map_to_treatment_string(treatment) do
    treatment.treatment
  end

  @spec map_treatments_to_treatments_string({:ok, %{String.t() => Split.Treatment.t()}}) ::
          %{String.t() => String.t()}
  def map_treatments_to_treatments_string(treatments) do
    treatments
    |> Enum.map(fn {key, treatment} -> {key, treatment.treatment} end)
    |> Enum.into(%{})
  end

  @spec map_treatments_to_treatments_with_config({:ok, %{String.t() => Split.Treatment.t()}}) ::
          %{String.t() => Split.TreatmentWithConfig.t()}
  def map_treatments_to_treatments_with_config(treatments) do
    treatments
    |> Enum.map(fn {key, treatment} -> {key, map_to_treatment_with_config(treatment)} end)
    |> Enum.into(%{})
  end
end
