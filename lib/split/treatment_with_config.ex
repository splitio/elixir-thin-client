defmodule Split.TreatmentWithConfig do
  @moduledoc """
  This module is a struct that represents a treatment with a configuration.

  ## Fields
    * `:treatment` - The treatment string value
    * `:config` - The treatment configuration string or nil if the treatment has no configuration
  """

  defstruct treatment: "control",
            config: nil

  @type t :: %__MODULE__{
          treatment: String.t(),
          config: String.t() | nil
        }
end
