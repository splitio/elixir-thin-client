defmodule Split.RPC.Message do
  @moduledoc """
  Represents an RPC message to be sent to splitd.
  """
  use Split.RPC.Opcodes

  @protocol_version 0x01
  @client_id "Splitd_Elixir-1.0.1"

  @type opcode :: unquote(Enum.reduce(@opcodes, &{:|, [], [&1, &2]}))
  @type protocol_version :: unquote(@protocol_version)

  @derive [{Msgpax.Packer, fields: [:v, :o, :a]}]
  defstruct v: @protocol_version,
            o: nil,
            a: []

  @type t :: %__MODULE__{
          v: protocol_version(),
          o: opcode(),
          a: list()
        }

  @type get_treatment_args ::
          {:key, Split.split_key()}
          | {:feature_name, String.t()}
          | {:attributes, Split.attributes()}

  @type get_treatments_args ::
          {:key, Split.split_key()}
          | {:feature_names, list(String.t())}
          | {:attributes, Split.attributes()}

  @doc """
  Builds a message to register a client in splitd.

  ## Examples

      iex> Message.register()
      %Message{v: 1, o: 0, a: ["123", "Splitd_Elixir-1.0.0", 1]}
  """
  @spec register() :: t()
  def register, do: %__MODULE__{o: @register_opcode, a: ["123", @client_id, 1]}

  @doc """
  Builds a message to get the treatment for a specific feature flag.

  ## Examples

      iex> Message.get_treatment(
      ...>   key: %{:matching_key => "user_key", :bucketing_key => "bucketing_key"},
      ...>   feature_name: "feature_name",
      ...>   attributes: %{}
      ...> )
      %Message{a: ["user_key", "bucketing_key", "feature_name", %{}], o: 17, v: 1}

      iex> Message.get_treatment(key: "user_key", feature_name: "feature_name")
      %Message{a: ["user_key", nil, "feature_name", %{}], o: 17, v: 1}
  """
  @spec get_treatment([get_treatment_args()]) :: t()
  def get_treatment(opts) do
    treatment_payload(opts, @get_treatment_opcode)
  end

  @doc """
  Builds a message to get the treatment for a specific feature flag with configuration.

  ## Examples

      iex> Message.get_treatment_with_config(
      ...>   key: %{:matching_key => "user_key", :bucketing_key => "bucketing_key"},
      ...>   feature_name: "feature_name",
      ...>   attributes: %{"foo" => "bar", :baz => 1}
      ...> )
      %Message{a: ["user_key", "bucketing_key", "feature_name", %{"foo" => "bar", :baz => 1}], o: 19, v: 1}

      iex> Message.get_treatment_with_config(
      ...>   key: "user_key",
      ...>   feature_name: "feature_name"
      ...> )
      %Message{a: ["user_key", nil, "feature_name", %{}], o: 19, v: 1}
  """
  @spec get_treatment_with_config([get_treatment_args()]) :: t()
  def get_treatment_with_config(opts) do
    treatment_payload(opts, @get_treatment_with_config_opcode)
  end

  @doc """
  Builds a message to get the treatments for multiple feature flags.

  ## Examples

      iex> Message.get_treatments(
      ...>   key: %{:matching_key => "user_key", :bucketing_key => "bucketing_key"},
      ...>   feature_names: ["feature_name1", "feature_name2"]
      ...> )
      %Message{
        a: ["user_key", "bucketing_key", ["feature_name1", "feature_name2"], %{}],
        o: 18,
        v: 1
      }

      iex> Message.get_treatments(
      ...>   key: "user_key",
      ...>   feature_names: ["feature_name1", "feature_name2"]
      ...> )
      %Message{a: ["user_key", nil, ["feature_name1", "feature_name2"], %{}], o: 18, v: 1}
  """
  @spec get_treatments([get_treatments_args()]) :: t()
  def get_treatments(opts) do
    treatment_payload(opts, @get_treatments_opcode, multiple: true)
  end

  @doc """
  Builds a message to get the treatments for multiple feature flags with configuration.

  ## Examples

      iex> Message.get_treatments_with_config(
      ...>   key: %{:matching_key => "user_key", :bucketing_key => "bucketing_key"},
      ...>   feature_names: ["feature_name1", "feature_name2"]
      ...> )
      %Message{
        a: ["user_key", "bucketing_key", ["feature_name1", "feature_name2"], %{}],
        o: 20,
        v: 1
      }

      iex> Message.get_treatments_with_config(
      ...>   key: "user_key",
      ...>   feature_names: ["feature_name1", "feature_name2"]
      ...> )
      %Message{
        a: ["user_key", nil, ["feature_name1", "feature_name2"], %{}],
        o: 20,
        v: 1
      }
  """
  @spec get_treatments_with_config([get_treatments_args()]) :: t()
  def get_treatments_with_config(opts) do
    treatment_payload(opts, @get_treatments_with_config_opcode, multiple: true)
  end

  @doc """
  Builds a message to get the treatments for a flag set.

  ## Examples

      iex> Message.get_treatments_by_flag_set(
      ...>   key: %{:matching_key => "user_key", :bucketing_key => "bucketing_key"},
      ...>   feature_name: "flag_set_name"
      ...> )
      %Message{
        a: ["user_key", "bucketing_key", "flag_set_name", %{}],
        o: 21,
        v: 1
      }

      iex> Message.get_treatments_by_flag_set(
      ...>   key: "user_key",
      ...>   feature_name: "flag_set_name"
      ...> )
      %Message{a: ["user_key", nil, "flag_set_name", %{}], o: 21, v: 1}
  """
  @spec get_treatments_by_flag_set([get_treatment_args()]) :: t()
  def get_treatments_by_flag_set(opts) do
    treatment_payload(opts, @get_treatments_by_flag_set_opcode, multiple: false)
  end

  @doc """
  Builds a message to get the treatments for a flag set with configuration.

  ## Examples

      iex> Message.get_treatments_with_config_by_flag_set(
      ...>   key: %{:matching_key => "user_key", :bucketing_key => "bucketing_key"},
      ...>   feature_name: "flag_set_name"
      ...> )
      %Message{
        a: ["user_key", "bucketing_key", "flag_set_name", %{}],
        o: 22,
        v: 1
      }

      iex> Message.get_treatments_with_config_by_flag_set(
      ...>   key: "user_key",
      ...>   feature_name: "flag_set_name"
      ...> )
      %Message{
        a: ["user_key", nil, "flag_set_name", %{}],
        o: 22,
        v: 1
      }
  """
  @spec get_treatments_with_config_by_flag_set([get_treatment_args()]) :: t()
  def get_treatments_with_config_by_flag_set(opts) do
    treatment_payload(opts, @get_treatments_with_config_by_flag_set_opcode, multiple: false)
  end

  @doc """
  Builds a message to get the treatments for multiple flag sets.

  ## Examples

      iex> Message.get_treatments_by_flag_sets(
      ...>   key: %{:matching_key => "user_key", :bucketing_key => "bucketing_key"},
      ...>   feature_names: ["flag_set_name1", "flag_set_name2"]
      ...> )
      %Message{
        a: ["user_key", "bucketing_key", ["flag_set_name1", "flag_set_name2"], %{}],
        o: 23,
        v: 1
      }

      iex> Message.get_treatments_by_flag_sets(
      ...>   key: "user_key",
      ...>   feature_names: ["flag_set_name1", "flag_set_name2"]
      ...> )
      %Message{a: ["user_key", nil, ["flag_set_name1", "flag_set_name2"], %{}], o: 23, v: 1}
  """
  @spec get_treatments_by_flag_sets([get_treatments_args()]) :: t()
  def get_treatments_by_flag_sets(opts) do
    treatment_payload(opts, @get_treatments_by_flag_sets_opcode, multiple: true)
  end

  @doc """
  Builds a message to get the treatments for multiple flag sets with configuration.

  ## Examples

      iex> Message.get_treatments_with_config_by_flag_sets(
      ...>   key: %{:matching_key => "user_key", :bucketing_key => "bucketing_key"},
      ...>   feature_names: ["flag_set_name1", "flag_set_name2"]
      ...> )
      %Message{
        a: ["user_key", "bucketing_key", ["flag_set_name1", "flag_set_name2"], %{}],
        o: 24,
        v: 1
      }

      iex> Message.get_treatments_with_config_by_flag_sets(
      ...>   key: %{:matching_key => "user_key"},
      ...>   feature_names: ["flag_set_name1", "flag_set_name2"]
      ...> )
      %Message{
        a: ["user_key", nil, ["flag_set_name1", "flag_set_name2"], %{}],
        o: 24,
        v: 1
      }
  """
  @spec get_treatments_with_config_by_flag_sets([get_treatments_args()]) :: t()
  def get_treatments_with_config_by_flag_sets(opts) do
    treatment_payload(opts, @get_treatments_with_config_by_flag_sets_opcode, multiple: true)
  end

  @doc """
  Builds a message to return information about an specific split (feature flag).

  ## Examples

      iex> Message.split("my_feature")
      %Message{v: 1, o: 161, a: ["my_feature"]}
  """
  @spec split(String.t()) :: t()
  def split(split_name), do: %__MODULE__{o: @split_opcode, a: [split_name]}

  @doc """
  Builds a message to return information about all the splits (feature flags) currently available in splitd.

  ## Examples

      iex> Message.splits()
      %Message{v: 1, o: 162, a: []}
  """
  @spec splits() :: t()
  def splits(), do: %__MODULE__{o: @splits_opcode}

  @doc """
  Builds a message to return the names of all the splits (feature flags) currently available in splitd.

  ## Examples

      iex> Message.split_names()
      %Message{v: 1, o: 160, a: []}
  """
  @spec split_names() :: t()
  def split_names(), do: %__MODULE__{o: @split_names_opcode}

  @doc """
  Message that creates and event and sends it to splitd so that it’s queued and submitted to Split.io.

  ## Examples

      iex> Message.track("user_key", "traffic_type", "my_event", 1.5, %{:foo => "bar"})
      %Message{
        v: 1,
        o: 128,
        a: ["user_key", "traffic_type", "my_event", 1.5, %{foo: "bar"}]
      }

      iex> Message.track("user_key", "traffic_type", "my_event")
      %Message{v: 1, o: 128, a: ["user_key", "traffic_type", "my_event", nil, %{}]}
  """
  @spec track(Split.split_key(), String.t(), String.t()) :: t()
  @spec track(Split.split_key(), String.t(), String.t(), number() | nil) :: t()
  @spec track(Split.split_key(), String.t(), String.t(), number() | nil, Split.properties()) ::
          t()
  def track(key, traffic_type, event_type, value \\ nil, properties \\ %{}) do
    matching_key =
      if is_map(key) do
        key.matching_key
      else
        key
      end

    %__MODULE__{
      o: @track_opcode,
      a: [matching_key, traffic_type, event_type, value, properties]
    }
  end

  @doc """
  Converts an opcode to the corresponding RPC call name.

  ## Examples

    iex> Message.opcode_to_rpc_name(@get_treatment_opcode)
    :get_treatment

    iex> Message.opcode_to_rpc_name(@get_treatment_with_config_opcode)
    :get_treatment_with_config

    iex> Message.opcode_to_rpc_name(@get_treatments_opcode)
    :get_treatments

    iex> Message.opcode_to_rpc_name(@get_treatments_with_config_opcode)
    :get_treatments_with_config

    iex> Message.opcode_to_rpc_name(@get_treatments_by_flag_set_opcode)
    :get_treatments_by_flag_set

    iex> Message.opcode_to_rpc_name(@get_treatments_with_config_by_flag_set_opcode)
    :get_treatments_with_config_by_flag_set

    iex> Message.opcode_to_rpc_name(@get_treatments_by_flag_sets_opcode)
    :get_treatments_by_flag_sets

    iex> Message.opcode_to_rpc_name(@get_treatments_with_config_by_flag_sets_opcode)
    :get_treatments_with_config_by_flag_sets

    iex> Message.opcode_to_rpc_name(@split_opcode)
    :split

    iex> Message.opcode_to_rpc_name(@splits_opcode)
    :splits

    iex> Message.opcode_to_rpc_name(@split_names_opcode)
    :split_names

    iex> Message.opcode_to_rpc_name(@track_opcode)
    :track
  """
  @spec opcode_to_rpc_name(opcode()) :: atom
  def opcode_to_rpc_name(@get_treatment_opcode), do: :get_treatment
  def opcode_to_rpc_name(@get_treatments_opcode), do: :get_treatments
  def opcode_to_rpc_name(@get_treatment_with_config_opcode), do: :get_treatment_with_config
  def opcode_to_rpc_name(@get_treatments_with_config_opcode), do: :get_treatments_with_config
  def opcode_to_rpc_name(@get_treatments_by_flag_set_opcode), do: :get_treatments_by_flag_set

  def opcode_to_rpc_name(@get_treatments_with_config_by_flag_set_opcode),
    do: :get_treatments_with_config_by_flag_set

  def opcode_to_rpc_name(@get_treatments_by_flag_sets_opcode), do: :get_treatments_by_flag_sets

  def opcode_to_rpc_name(@get_treatments_with_config_by_flag_sets_opcode),
    do: :get_treatments_with_config_by_flag_sets

  def opcode_to_rpc_name(@split_opcode), do: :split
  def opcode_to_rpc_name(@splits_opcode), do: :splits
  def opcode_to_rpc_name(@split_names_opcode), do: :split_names
  def opcode_to_rpc_name(@track_opcode), do: :track

  defp treatment_payload(data, opcode, opts \\ []) do
    features_key =
      if Keyword.get(opts, :multiple, false), do: :feature_names, else: :feature_name

    key = Keyword.fetch!(data, :key)

    {matching_key, bucketing_key} =
      if is_map(key) do
        {key.matching_key, Map.get(key, :bucketing_key, nil)}
      else
        {key, nil}
      end

    feature_name = Keyword.fetch!(data, features_key)
    attributes = Keyword.get(data, :attributes, %{})

    %__MODULE__{
      o: opcode,
      a: [
        matching_key,
        bucketing_key,
        feature_name,
        attributes
      ]
    }
  end
end
