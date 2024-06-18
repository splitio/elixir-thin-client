defmodule Split.Telemetry do
  @moduledoc """
  Telemetry events for the Split SDK.

  The following events are emitted by the Split SDK:

  * `[:split, :impression]` - Emitted when a treatment is assigned to a user. This is equivalent to an impression in the Split system.
    * measurements:
      * `impression` - A `%Split.Impression{}` struct containing the following fields:
        * `key` - The user key.
        * `feature` - The feature name.
        * `treatment` - The treatment assigned to the user.
        * `label` - The label assigned to the treatment.
        * `change_number` - The change number of the treatment.
        * `timestamp` - The timestamp of the treatment assignment.
  """
  alias Split.Treatment

  def send_impression(user_key, feature_name, %Treatment{} = treatment) do
    :telemetry.execute([:split, :impression], %{}, %{
      impression: %Split.Impression{
        key: user_key,
        feature: feature_name,
        treatment: treatment.treatment,
        label: treatment.label,
        change_number: treatment.change_number,
        timestamp: treatment.timestamp
      }
    })
  end
end
