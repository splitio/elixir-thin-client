defmodule Split do
  @moduledoc """
  The Split.io Elixir thin client.

  This module provides a simple API to interact with the Split.io service
  via the [Split Daemon (splitd)](https://help.split.io/hc/en-us/articles/18305269686157-Split-Daemon-splitd).

  ## Adding Split to Your Supervision Tree

  The most basic approach is to add `Split` as a child of your application's
  top-most supervisor, i.e. `lib/my_app/application.ex`.

  ```elixir
  defmodule MyApp.Application do
    use Application

    def start(_type, _args) do
      children = [
        # ... other children ...
        {Split, [socket_path: "/var/run/split.sock"]}
      ]

      opts = [strategy: :one_for_one, name: MyApp.Supervisor]
      Supervisor.start_link(children, opts)
    end
  end
  ```

  You can also start `Split` dynamically by calling `Split.Supervisor.start_link/1`:

  ```elixir
  Split.Supervisor.start_link(opts)
  ```

  ### Options

  `Split` takes a number of keyword arguments as options when starting. The following options are available:

  - `:socket_path`: **REQUIRED** The path to the splitd socket file. For example `/var/run/splitd.sock`.
  - `:pool_size`: **OPTIONAL** The size of the pool of connections to the splitd daemon. Default is the number of online schedulers in the Erlang VM (See: https://www.erlang.org/doc/apps/erts/erl_cmd.html).
  - `:connect_timeout`: **OPTIONAL** The timeout in milliseconds to connect to the splitd daemon. Default is `1000`.


  ## Using the API

  Once you have started Split, you are ready to start interacting with the Split.io splitd's daemon to access feature flags and configurations.

  ```elixir
  Split.get_treatment("user_key", "feature_name")
  ```
  """
  alias Split.Telemetry
  alias Split.Sockets.Pool
  alias Split.Treatment
  alias Split.RPC.Message
  alias Split.RPC.ResponseParser

  @type t :: %Split{
          name: String.t(),
          traffic_type: String.t(),
          killed: boolean(),
          treatments: [String.t()],
          change_number: integer(),
          configurations: map(),
          default_treatment: String.t(),
          flag_sets: [String.t()]
        }

  @typedoc "An option that can be provided when starting `Split`."
  @type option ::
          {:socket_path, String.t()}
          | {:pool_size, non_neg_integer()}
          | {:connect_timeout, non_neg_integer()}

  @type options :: [option()]

  @type split_key :: String.t() | {:matching_key, String.t(), :bucketing_key, String.t() | nil}

  defstruct [
    :name,
    :traffic_type,
    :killed,
    :treatments,
    :change_number,
    :configurations,
    :default_treatment,
    :flag_sets
  ]

  @doc """
  Builds a child specification to use in a Supervisor.

  Normally not called directly by your code. Instead, it will be
  called by your application's Supervisor once you add `Split`
  to its supervision tree.
  """
  @spec child_spec(options()) :: Supervisor.child_spec()
  defdelegate child_spec(options), to: Split.Supervisor

  @spec get_treatment(split_key(), String.t(), map() | nil) :: Treatment.t()
  def get_treatment(key, feature_name, attributes \\ %{}) do
    request =
      Message.get_treatment(
        key: key,
        feature_name: feature_name,
        attributes: attributes
      )

    execute_rpc(request)
  end

  @spec get_treatment_with_config(split_key(), String.t(), map() | nil) ::
          Treatment.t()
  def get_treatment_with_config(key, feature_name, attributes \\ %{}) do
    request =
      Message.get_treatment_with_config(
        key: key,
        feature_name: feature_name,
        attributes: attributes
      )

    execute_rpc(request)
  end

  @spec get_treatments(split_key(), [String.t()], map() | nil) :: %{
          String.t() => Treatment.t()
        }
  def get_treatments(key, feature_names, attributes \\ %{}) do
    request =
      Message.get_treatments(
        key: key,
        feature_names: feature_names,
        attributes: attributes
      )

    execute_rpc(request)
  end

  @spec get_treatments_with_config(split_key(), [String.t()], map() | nil) :: %{
          String.t() => Treatment.t()
        }
  def get_treatments_with_config(key, feature_names, attributes \\ %{}) do
    request =
      Message.get_treatments_with_config(
        key: key,
        feature_names: feature_names,
        attributes: attributes
      )

    execute_rpc(request)
  end

  @spec track(split_key(), String.t(), String.t(), number() | nil, map() | nil) :: boolean()
  def track(key, traffic_type, event_type, value \\ nil, properties \\ %{}) do
    request = Message.track(key, traffic_type, event_type, value, properties)
    execute_rpc(request)
  end

  @spec split_names() :: %{split_names: String.t()}
  def split_names do
    request = Message.split_names()
    execute_rpc(request)
  end

  @spec split(String.t()) :: Split.t()
  def split(name) do
    request = Message.split(name)

    execute_rpc(request)
  end

  @spec splits() :: [Split.t()]
  def splits do
    request = Message.splits()
    execute_rpc(request)
  end

  defp execute_rpc(request, opts \\ []) do
    telemetry_span_context = :erlang.make_ref()

    metadata = %{
      rpc_call: Message.opcode_to_rpc_name(request.o),
      telemetry_span_context: telemetry_span_context
    }

    Telemetry.span(:rpc, metadata, fn ->
      request
      |> Pool.send_message(opts)
      |> ResponseParser.parse_response(request, span_context: telemetry_span_context)
      |> case do
        data = response ->
          {response, %{response: data}}
      end
    end)
  end
end
