defmodule Split.Telemetry do
  @moduledoc """
  Telemetry events for the Split SDK.

  The following events are emitted by the Split SDK:

  ### RPC Start

  `[:split, :rpc, :start]` - Emitted when an RPC call is started.


  #### Measurements

    * `monotonic_time` - The time when the event was emitted.

  #### Metadata

    * `rpc_call` - The RPC call name.

  ### RPC Stop

  `[:split, :rpc, :stop]` - Emitted when an RPC call ends.

  #### Measurements

    * `monotonic_time` - The time when the event was emitted.
    * `:duration` - Time taken from the RPC start event.

  #### Metadata

    * `rpc_call` - The RPC call name.
    * `response` - The response from the RPC call.
    * `error` - The error message if the RPC call fails.

  ### RPC Fallback

  `[:split, :rpc, :fallback]` - Emitted when an RPC call falls back to the fallback mechanism.

  #### Measurements

    * `monotonic_time` - The time when the event was emitted.

  #### Metadata

      * `rpc_call` - The RPC call name.
      * `response` - The generated callback response from the RPC call.

  ### Queue Start

  `[:split, :queue, :start]` - Executed before checking out a socket connection from the pool.

  #### Measurements

    * `monotonic_time` - The time when the event was emitted.

  #### Metadata

    * `message` - The message being sent to the Splitd daemon.
    * `pool_name` - The name of the pool being used.

  ### Queue Stop

  `[:split, :queue, :stop]` - Executed after checking out a socket connection from the pool.

  #### Measurements

    * `monotonic_time` - The time when the event was emitted.
    * `:duration` - The time taken to check out a pool connection.

  #### Metadata

    * `message` - The message being sent to the Splitd daemon.
    * `pool_name` - The name of the pool being used.
    * `error` - The error message if the RPC call fails.

  ### Queue Exception

  `[:split, :queue, :exception]` - Executed when an exception occurs while checking out a socket connection from the pool.

  #### Measurements

    * `monotonic_time` - The time when the event was emitted.
    * `:duration` - The time taken since queue start event before raising an exception.

  #### Metadata

    * `message` - The message being sent to the Splitd daemon.
    * `pool_name` - The name of the pool being used.
    * `kind` - The exception type.
    * `reason` - The exception reason.
    * `stacktrace` - The exception stacktrace.

  ### Connect Start

  `[:split, :connect, :start]` - Emitted when a connection to the Splitd daemon is established.

  #### Measurements

    * `monotonic_time` - The time when the event was emitted.

  #### Metadata

    * `socket_path` - The path to the socket file.
    * `pool_name` - The name of the pool being used.

  ### Connect Stop

  `[:split, :connect, :stop]` - Emitted when a connection to the Splitd daemon is established.

  #### Measurements

    * `monotonic_time` - The time when the event was emitted.
    * `:duration` - The time taken to establish a connection.

  #### Metadata

    * `socket_path` - The path to the socket file.
    * `pool_name` - The name of the pool being used.
    * `error` - The error message if the connection fails.

  ### Send Start

  `[:split, :send, :start]` - Emitted before message is sent to the connected Splitd socket.

  #### Measurements

     * `monotonic_time` - The time when the event was emitted.

  #### Metadata

    * `request` - The message being sent to the Splitd daemon.

  ### Send Stop

  `[:split, :send, :stop]` - Emitted when a message is sent to the connected Splitd socket.

  #### Measurements

    * `monotonic_time` - The time when the event was emitted.
    * `:duration` - The time taken to send a message.

  #### Metadata

    * `request` - The message being sent to the Splitd daemon.
    * `error` - The error message if the message fails to send.

  ### Receive Start

  `[:split, :receive, :start]` - Emitted before receiving a message from the connected Splitd socket.

  #### Measurements

    * `monotonic_time` - The time when the event was emitted.

  #### Metadata

    * `request` - The message being received from the Splitd daemon.

  ### Receive Stop

  `[:split, :receive, :stop]` - Emitted when a message is received from the connected Splitd socket.

  #### Measurements

    * `monotonic_time` - The time when the event was emitted.
    * `:duration` - The time taken to receive a message.

  #### Metadata

    * `request` - The message being received from the Splitd daemon.
    * `response` - The response received from the Splitd daemon.
    * `error` - The error message if the message fails to receive.

  ### Impression

  `[:split, :impression]` - Emitted when a treatment is assigned to a user. This is equivalent to an impression in the Split system.

  #### measurements:
    * `impression` - A `%Split.Impression{}` struct containing the following fields:
      * `key` - The user key.
      * `feature` - The feature name.
      * `treatment` - The treatment assigned to the user.
      * `label` - The label assigned to the treatment.
      * `change_number` - The change number of the treatment.
      * `timestamp` - The timestamp of the treatment assignment.
  """
  alias Split.Treatment

  defstruct span_name: nil, telemetry_span_context: nil, start_time: nil, start_metadata: nil

  @opaque t :: %__MODULE__{
            span_name: atom(),
            telemetry_span_context: reference(),
            start_time: integer(),
            start_metadata: :telemetry.event_metadata()
          }

  @app_name :split

  @doc """
  Emits a `start` telemetry span.
  """
  @spec start(atom(), :telemetry.event_metadata(), :telemetry.event_measurements()) :: t()
  def start(span_name, metadata \\ %{}, extra_measurements \\ %{}) do
    telemetry_span_context = make_ref()
    measurements = Map.put_new_lazy(extra_measurements, :monotonic_time, &monotonic_time/0)
    metadata = Map.put(metadata, :telemetry_span_context, telemetry_span_context)

    :telemetry.execute([@app_name, span_name, :start], measurements, metadata)

    %__MODULE__{
      span_name: span_name,
      telemetry_span_context: telemetry_span_context,
      start_time: measurements[:monotonic_time],
      start_metadata: metadata
    }
  end

  @doc """
  Emits a telemetry `stop` event.
  """
  @spec stop(t(), :telemetry.event_metadata(), :telemetry.event_measurements()) :: :ok
  def stop(start_event, metadata \\ %{}, extra_measurements \\ %{}) do
    measurements = Map.put_new_lazy(extra_measurements, :monotonic_time, &monotonic_time/0)

    measurements =
      Map.put(measurements, :duration, measurements[:monotonic_time] - start_event.start_time)

    metadata = Map.merge(start_event.start_metadata, metadata)

    :telemetry.execute(
      [@app_name, start_event.span_name, :stop],
      measurements,
      metadata
    )
  end

  @doc """
  Emits a telemetry `exception` event.
  """
  @spec exception(
          t(),
          atom(),
          term(),
          Exception.stacktrace()
        ) :: :ok
  def exception(
        start_event,
        kind,
        reason,
        stacktrace
      ) do
    measurements = Map.put_new_lazy(%{}, :monotonic_time, &monotonic_time/0)

    measurements =
      Map.put(measurements, :duration, measurements[:monotonic_time] - start_event.start_time)

    metadata =
      start_event.start_metadata
      |> Map.merge(%{
        kind: kind,
        reason: reason,
        stacktrace: stacktrace
      })

    :telemetry.execute([@app_name, start_event.span_name, :exception], measurements, metadata)
  end

  @doc """
  Wraps a function in a telemetry span.
  """
  @spec span(atom(), :telemetry.event_metadata(), :telemetry.span_function()) ::
          :telemetry.span_result()
  def span(span_name, metadata, function) do
    :telemetry.span([@app_name, span_name], metadata, function)
  end

  @doc """
  Emits a one-off telemetry event.
  """
  @spec span_event(
          [atom(), ...],
          reference(),
          :telemetry.event_measurements(),
          :telemetry.event_metadata()
        ) ::
          :ok
  def span_event(
        [_ | _] = span_name,
        telemetry_span_context,
        metadata \\ %{},
        measurements \\ %{}
      ) do
    measurements = Map.put_new_lazy(measurements, :monotonic_time, &monotonic_time/0)
    metadata = Map.put(metadata, :telemetry_span_context, telemetry_span_context)

    :telemetry.execute([@app_name | span_name], measurements, metadata)
  end

  @doc """
  Emits a telemetry `impression` event when a Split treatment has been evaluated.
  """
  @spec send_impression(String.t(), String.t(), Treatment.t()) :: :ok
  def send_impression(key, feature_name, %Treatment{} = treatment) do
    :telemetry.execute([@app_name, :impression], %{}, %{
      impression: %Split.Impression{
        key: key,
        feature: feature_name,
        treatment: treatment.treatment,
        label: treatment.label,
        change_number: treatment.change_number,
        timestamp: treatment.timestamp
      }
    })
  end

  @spec monotonic_time :: integer()
  defdelegate monotonic_time, to: System
end
