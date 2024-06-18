defmodule Split.Impression do
  defstruct [
    :key,
    :feature,
    :treatment,
    :label,
    :change_number,
    :timestamp
  ]

  @type t :: %__MODULE__{
          key: String.t(),
          feature: String.t(),
          treatment: String.t(),
          label: String.t(),
          change_number: integer(),
          timestamp: integer()
        }
end
