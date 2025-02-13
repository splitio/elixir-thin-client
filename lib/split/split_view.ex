defmodule Split.SplitView do
  @moduledoc """
  This module is a struct that contains information of a feature flag.

  ## Fields
    * `:name` - The name of the feature flag
    * `:traffic_type` - The traffic type of the feature flag
    * `:killed` - A boolean that indicates if the feature flag is killed
    * `:treatments` - The list of treatments of the feature flag
    * `:change_number` - The change number of the feature flag
    * `:configs` - The map of treatments and their configurations
    * `:default_treatment` - The default treatment of the feature flag
    * `:sets` - The list of flag sets that the feature flag belongs to
    * `:impressions_disabled` - A boolean that indicates if the tracking of impressions is disabled
  """

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
          configs: %{String.t() => String.t() | nil},
          default_treatment: String.t(),
          sets: [String.t()],
          impressions_disabled: boolean()
        }
end
