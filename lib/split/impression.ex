defmodule Split.Impression do
  defstruct key: nil,
            bucketing_key: nil,
            feature: nil,
            treatment: "control",
            config: nil,
            label: nil,
            change_number: nil,
            timestamp: nil

  @type t :: %__MODULE__{
          key: String.t(),
          bucketing_key: String.t() | nil,
          feature: String.t(),
          treatment: String.t(),
          config: String.t() | nil,
          label: String.t() | nil,
          change_number: integer() | nil,
          timestamp: integer() | nil
        }

  @spec build_from_daemon_response(map(), String.t(), String.t() | nil, String.t()) :: t
  def build_from_daemon_response(treatment_payload, key, bucketing_key, feature) do
    treatment = treatment_payload["t"]
    config = treatment_payload["c"]
    label = get_in(treatment_payload, ["l", "l"])
    change_number = get_in(treatment_payload, ["l", "c"])
    timestamp = get_in(treatment_payload, ["l", "m"])

    %Split.Impression{
      key: key,
      bucketing_key: bucketing_key,
      feature: feature,
      treatment: treatment,
      label: label,
      config: config,
      change_number: change_number,
      timestamp: timestamp
    }
  end
end
