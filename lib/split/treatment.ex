defmodule Split.Treatment do
  defstruct [
    :treatment,
    label: nil,
    config: nil,
    change_number: nil,
    timestamp: nil
  ]

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
end
