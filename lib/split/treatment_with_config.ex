defmodule Split.TreatmentWithConfig do
  defstruct treatment: "control",
            config: nil

  @type t :: %__MODULE__{
          treatment: String.t(),
          config: String.t() | nil
        }
end
