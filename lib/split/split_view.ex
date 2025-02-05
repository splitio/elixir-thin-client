defmodule Split.SplitView do
  defstruct [
    :name,
    :traffic_type,
    :killed,
    :treatments,
    :change_number,
    :configs,
    :default_treatment,
    :sets,
    :impressions_disabled
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          traffic_type: String.t(),
          killed: boolean(),
          treatments: [String.t()],
          change_number: integer(),
          configs: map(),
          default_treatment: String.t(),
          sets: [String.t()],
          impressions_disabled: boolean()
        }
end
