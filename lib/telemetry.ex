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

  @doc false
  # emits a `start` telemetry event and returns the the start time
  def start(event, meta \\ %{}, extra_measurements \\ %{}) do
    start_time = System.monotonic_time()

    :telemetry.execute(
      [:split, event, :start],
      Map.merge(extra_measurements, %{system_time: System.system_time()}),
      meta
    )

    start_time
  end

  @doc false
  # Emits a stop event.
  def stop(event, start_time, meta \\ %{}, extra_measurements \\ %{}) do
    end_time = System.monotonic_time()
    measurements = Map.merge(extra_measurements, %{duration: end_time - start_time})

    :telemetry.execute(
      [:split, event, :stop],
      measurements,
      meta
    )
  end

  @doc false
  def exception(event, start_time, kind, reason, stack, meta \\ %{}, extra_measurements \\ %{}) do
    end_time = System.monotonic_time()
    measurements = Map.merge(extra_measurements, %{duration: end_time - start_time})

    meta =
      meta
      |> Map.put(:kind, kind)
      |> Map.put(:reason, reason)
      |> Map.put(:stacktrace, stack)

    :telemetry.execute([:split, event, :exception], measurements, meta)
  end

  @spec send_impression(String.t(), String.t(), Treatment.t()) :: :ok
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
