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
        {Split, [socket_path: "/var/run/split.sock", fallback_enabled: true]}
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
  - `:fallback_enabled`: **OPTIONAL** A boolean that indicates wether we should return errors when RPC communication fails or falling back to a default value . Default is `false`.
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
          | {:fallback_enabled, boolean()}
          | {:pool_size, non_neg_integer()}
          | {:connect_timeout, non_neg_integer()}

  @type options :: [option()]

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

  @spec get_treatment(String.t(), String.t(), String.t() | nil, map() | nil) ::
          {:ok, Treatment.t()} | {:error, term()}
  def get_treatment(user_key, feature_name, bucketing_key \\ nil, attributes \\ %{}) do
    request =
      Message.get_treatment(
        user_key: user_key,
        feature_name: feature_name,
        bucketing_key: bucketing_key,
        attributes: attributes
      )

    execute_rpc(request)
  end

  @spec get_treatment_with_config(String.t(), String.t(), String.t() | nil, map() | nil) ::
          {:ok, Treatment.t()} | {:error, term()}
  def get_treatment_with_config(user_key, feature_name, bucketing_key \\ nil, attributes \\ %{}) do
    request =
      Message.get_treatment_with_config(
        user_key: user_key,
        feature_name: feature_name,
        bucketing_key: bucketing_key,
        attributes: attributes
      )

    execute_rpc(request)
  end

  @spec get_treatments(String.t(), [String.t()], String.t() | nil, map() | nil) ::
          {:ok, %{String.t() => Treatment.t()}} | {:error, term()}
  def get_treatments(user_key, feature_names, bucketing_key \\ nil, attributes \\ %{}) do
    request =
      Message.get_treatments(
        user_key: user_key,
        feature_names: feature_names,
        bucketing_key: bucketing_key,
        attributes: attributes
      )

    execute_rpc(request)
  end

  @spec get_treatments_with_config(String.t(), [String.t()], String.t() | nil, map() | nil) ::
          {:ok, %{String.t() => Treatment.t()}} | {:error, term()}
  def get_treatments_with_config(user_key, feature_names, bucketing_key \\ nil, attributes \\ %{}) do
    request =
      Message.get_treatments_with_config(
        user_key: user_key,
        feature_names: feature_names,
        bucketing_key: bucketing_key,
        attributes: attributes
      )

    execute_rpc(request)
  end

  @spec track(String.t(), String.t(), String.t(), term(), map()) :: :ok | {:error, term()}
  def track(user_key, traffic_type, event_type, value \\ nil, properties \\ %{}) do
    request = Message.track(user_key, traffic_type, event_type, value, properties)
    execute_rpc(request)
  end

  @spec split_names() :: {:ok, %{split_names: String.t()}} | {:error, term()}
  def split_names do
    request = Message.split_names()
    execute_rpc(request)
  end

  @spec split(String.t()) :: {:ok, Split.t()} | {:error, term()}
  def split(name) do
    request = Message.split(name)

    execute_rpc(request)
  end

  @spec splits() :: {:ok, [Split.t()]} | {:error, term()}
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
        :ok ->
          {:ok, %{}}

        {:ok, data} = response ->
          {response, %{response: data}}

        {:error, reason} = error ->
          {error, %{error: reason}}
      end
    end)
  end
end
