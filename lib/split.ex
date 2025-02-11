defmodule Split do
  @moduledoc """
  The Split.io Elixir thin client.

  This module provides a simple API to interact with the Split.io service
  via the [Split Daemon (splitd)](https://help.split.io/hc/en-us/articles/18305269686157-Split-Daemon-splitd).

  ## Adding Split to Your Supervision Tree

  The most basic approach is to add `Split` as a child of your application's
  top-most supervisor, i.e. `lib/my_app/application.ex`.

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

  You can also start `Split` dynamically by calling `Split.Supervisor.start_link/1`:

      Split.Supervisor.start_link(opts)

  ### Options

  `Split` takes a number of keyword arguments as options when starting. The following options are available:

  - `:socket_path`: **REQUIRED** The path to the splitd socket file. For example `/var/run/splitd.sock`.
  - `:pool_size`: **OPTIONAL** The size of the pool of connections to the splitd daemon. Default is the number of online schedulers in the Erlang VM (See: https://www.erlang.org/doc/apps/erts/erl_cmd.html).
  - `:connect_timeout`: **OPTIONAL** The timeout in milliseconds to connect to the splitd daemon. Default is `1000`.


  ## Using the API

  Once you have started Split, you are ready to start interacting with the Split.io splitd's daemon to access feature flags and configurations.

      Split.get_treatment("user_key", "feature_name")
  """
  alias Split.Telemetry
  alias Split.Sockets.Pool
  alias Split.TreatmentWithConfig
  alias Split.SplitView
  alias Split.RPC.Message
  alias Split.RPC.ResponseParser

  @typedoc "An option that can be provided when starting `Split`."
  @type option ::
          {:socket_path, String.t()}
          | {:pool_size, non_neg_integer()}
          | {:connect_timeout, non_neg_integer()}

  @typedoc "Options to start the `Split` application."
  @type options :: [option()]

  @typedoc """
  The [traffic type identifier](https://help.split.io/hc/en-us/articles/360019916311-Traffic-types).
  It can be either a string or a map with a matching key and an optional bucketing key.
  """
  @type split_key ::
          String.t()
          | %{required(:matchingKey) => String.t(), optional(:bucketingKey) => String.t() | nil}

  @doc """
  Builds a child specification to use in a Supervisor.

  Normally not called directly by your code. Instead, it will be
  called by your application's Supervisor once you add `Split`
  to its supervision tree.
  """
  @spec child_spec(options()) :: Supervisor.child_spec()
  defdelegate child_spec(options), to: Split.Supervisor

  @doc """
  Gets the treatment string for a given key, feature flag name and optional attributes.

  ## Examples

      iex> Split.get_treatment("user_id", "located_in_usa")
      "off"
      iex> Split.get_treatment("user_id", "located_in_usa", %{country: "USA"})
      "on"
  """
  @spec get_treatment(split_key(), String.t(), map() | nil) :: String.t()
  def get_treatment(key, feature_name, attributes \\ %{}) do
    request =
      Message.get_treatment(
        key: key,
        feature_name: feature_name,
        attributes: attributes
      )

    execute_rpc(request) |> impression_to_treatment()
  end

  @doc """
  Gets the treatment with config for a given key, feature flag name and optional attributes.

  ## Examples

      iex> Split.get_treatment_with_config("user_id", "located_in_usa")
      %Split.TreatmentWithConfig{treatment: "off", config: nil}
      iex> Split.get_treatment("user_id", "located_in_usa", %{country: "USA"})
      %Split.TreatmentWithConfig{treatment: "on", config: nil}
  """
  @spec get_treatment_with_config(split_key(), String.t(), map() | nil) :: TreatmentWithConfig.t()
  def get_treatment_with_config(key, feature_name, attributes \\ %{}) do
    request =
      Message.get_treatment_with_config(
        key: key,
        feature_name: feature_name,
        attributes: attributes
      )

    execute_rpc(request) |> impression_to_treatment_with_config()
  end

  @doc """
  Gets a map of feature flag names to treatments for a given key, list of feature flag names and optional attributes.

  ## Examples

      iex> Split.get_treatments("user_id", ["located_in_usa"])
      %{"located_in_usa" => "off"}
      iex> Split.get_treatments("user_id", ["located_in_usa"], %{country: "USA"})
      %{"located_in_usa" => "on"}
  """
  @spec get_treatments(split_key(), [String.t()], map() | nil) :: %{
          String.t() => String.t()
        }
  def get_treatments(key, feature_names, attributes \\ %{}) do
    request =
      Message.get_treatments(
        key: key,
        feature_names: feature_names,
        attributes: attributes
      )

    execute_rpc(request) |> impressions_to_treatments()
  end

  @doc """
  Gets a map of feature flag names to treatments with config for a given key, list of feature flag names and optional attributes.

  ## Examples

      iex> Split.get_treatments_with_config("user_id", ["located_in_usa"])
      %{"located_in_usa" => %Split.TreatmentWithConfig{treatment: "off", config: nil}}
      iex> Split.get_treatments_with_config("user_id", ["located_in_usa"], %{country: "USA"})
      %{"located_in_usa" => %Split.TreatmentWithConfig{treatment: "on", config: nil}}
  """
  @spec get_treatments_with_config(split_key(), [String.t()], map() | nil) :: %{
          String.t() => TreatmentWithConfig.t()
        }
  def get_treatments_with_config(key, feature_names, attributes \\ %{}) do
    request =
      Message.get_treatments_with_config(
        key: key,
        feature_names: feature_names,
        attributes: attributes
      )

    execute_rpc(request) |> impressions_to_treatments_with_config()
  end

  @doc """
  Gets a map of feature flag names to treatment strings for a given key, flag set name and optional attributes.

  ## Examples

      iex> Split.get_treatments_by_flag_set("user_id", "frontend_flags")
      %{"located_in_usa" => "off"}
      iex> Split.get_treatments_by_flag_set("user_id", "frontend_flags", %{country: "USA"})
      %{"located_in_usa" => "on"}
  """
  @spec get_treatments_by_flag_set(split_key(), String.t(), map() | nil) :: %{
          String.t() => String.t()
        }
  def get_treatments_by_flag_set(key, flag_set_name, attributes \\ %{}) do
    request =
      Message.get_treatments_by_flag_set(
        key: key,
        feature_name: flag_set_name,
        attributes: attributes
      )

    execute_rpc(request) |> impressions_to_treatments()
  end

  @doc """
  Gets a map of feature flag names to treatments with config for a given key, flag set name and optional attributes.

  ## Examples

      iex> Split.get_treatments_with_config_by_flag_set("user_id", "frontend_flags")
      %{"located_in_usa" => %Split.TreatmentWithConfig{treatment: "off", config: nil}}
      iex> Split.get_treatments_with_config_by_flag_set("user_id", "frontend_flags", %{country: "USA"})
      %{"located_in_usa" => %Split.TreatmentWithConfig{treatment: "on", config: nil}}
  """
  @spec get_treatments_with_config_by_flag_set(
          split_key(),
          String.t(),
          map() | nil
        ) ::
          %{String.t() => TreatmentWithConfig.t()}
  def get_treatments_with_config_by_flag_set(
        key,
        flag_set_name,
        attributes \\ %{}
      ) do
    request =
      Message.get_treatments_with_config_by_flag_set(
        key: key,
        feature_name: flag_set_name,
        attributes: attributes
      )

    execute_rpc(request) |> impressions_to_treatments_with_config()
  end

  @doc """
  Gets a map of feature flag names to treatment strings for a given key, flag set name and optional attributes.

  ## Examples

      iex> Split.get_treatments_by_flag_sets("user_id", ["frontend_flags", "backend_flags"])
      %{"located_in_usa" => "off"}
      iex> Split.get_treatments_by_flag_sets("user_id", ["frontend_flags", "backend_flags"], %{country: "USA"})
      %{"located_in_usa" => "on"}
  """
  @spec get_treatments_by_flag_sets(split_key(), [String.t()], map() | nil) ::
          %{String.t() => String.t()}
  def get_treatments_by_flag_sets(
        key,
        flag_set_names,
        attributes \\ %{}
      ) do
    request =
      Message.get_treatments_by_flag_sets(
        key: key,
        feature_names: flag_set_names,
        attributes: attributes
      )

    execute_rpc(request) |> impressions_to_treatments()
  end

  @doc """
  Gets a map of feature flag names to treatments with config for a given key, flag set name and optional attributes.

  ## Examples

      iex> Split.get_treatments_with_config_by_flag_sets("user_id", ["frontend_flags", "backend_flags"])
      %{"located_in_usa" => %Split.TreatmentWithConfig{treatment: "off", config: nil}}
      iex> Split.get_treatments_with_config_by_flag_sets("user_id", ["frontend_flags", "backend_flags"], %{country: "USA"})
      %{"located_in_usa" => %Split.TreatmentWithConfig{treatment: "on", config: nil}}
  """
  @spec get_treatments_with_config_by_flag_sets(
          split_key(),
          [String.t()],
          map() | nil
        ) ::
          %{String.t() => TreatmentWithConfig.t()}
  def get_treatments_with_config_by_flag_sets(
        key,
        flag_set_names,
        attributes \\ %{}
      ) do
    request =
      Message.get_treatments_with_config_by_flag_sets(
        key: key,
        feature_names: flag_set_names,
        attributes: attributes
      )

    execute_rpc(request) |> impressions_to_treatments_with_config()
  end

  @doc """
  Tracks an event for a given key, traffic type, event type, and optional numeric value and map of properties.
  Returns `true` if the event was successfully tracked, or `false` otherwise, e.g. if the Split daemon is not running or cannot be reached.

  See: https://help.split.io/hc/en-us/articles/26988707417869-Elixir-Thin-Client-SDK#track

  ## Examples

      iex> Split.track("user_id", "user", "my-event")
      true
      iex> Split.track("user_id", "user", "my-event", 42)
      true
      iex> Split.track("user_id", "user", "my-event", 42, %{property1: "value1"})
      true
  """
  @spec track(split_key(), String.t(), String.t(), number() | nil, map() | nil) :: boolean()
  def track(key, traffic_type, event_type, value \\ nil, properties \\ %{}) do
    request = Message.track(key, traffic_type, event_type, value, properties)
    execute_rpc(request)
  end

  @doc """
  Gets the list of all feature flag names.

  ## Examples

      iex> Split.split_names()
      ["located_in_usa"]
  """
  @spec split_names() :: [String.t()]
  def split_names do
    request = Message.split_names()
    execute_rpc(request)
  end

  @doc """
  Gets the data of a given feature flag name in `SplitView` format.

  ## Examples

      iex> Split.split("located_in_usa")
      %Split.SplitView{
        name: "located_in_usa",
        traffic_type: "user",
        killed: false,
        treatments: ["on", "off"],
        change_number: 123456,
        configs: %{ "on" => nil, "off" => nil },
        default_treatment: "off",
        sets: ["frontend_flags"],
        impressions_disabled: false
      }
  """
  @spec split(String.t()) :: SplitView.t() | nil
  def split(name) do
    request = Message.split(name)

    execute_rpc(request)
  end

  @doc """
  Gets the data of all feature flags in `SplitView` format.

  ## Examples

      iex> Split.splits()
      [%Split.SplitView{
        name: "located_in_usa",
        traffic_type: "user",
        killed: false,
        treatments: ["on", "off"],
        change_number: 123456,
        configs: %{ "on" => nil, "off" => nil },
        default_treatment: "off",
        sets: ["frontend_flags"],
        impressions_disabled: false
      }]
  """
  @spec splits() :: [SplitView.t()]
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

  defp impression_to_treatment(impression) do
    impression.treatment
  end

  defp impression_to_treatment_with_config(impression) do
    %TreatmentWithConfig{treatment: impression.treatment, config: impression.config}
  end

  defp impressions_to_treatments(impressions) do
    Enum.into(impressions, %{}, fn {key, impression} ->
      {key, impression_to_treatment(impression)}
    end)
  end

  defp impressions_to_treatments_with_config(impressions) do
    Enum.into(impressions, %{}, fn {key, impression} ->
      {key, impression_to_treatment_with_config(impression)}
    end)
  end
end
