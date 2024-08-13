defmodule Split.RPC.MessageType do
  defmacro __using__(_) do
    quote do
      @register_opcode 0x00
      @get_treatment_opcode 0x11
      @get_treatments_opcode 0x12
      @get_treatment_with_config_opcode 0x13
      @get_treatments_with_config_opcode 0x14
      @split_opcode 0xA1
      @splits_opcode 0xA2
      @split_names_opcode 0xA0
      @track_opcode 0x80

      @message_type [
        @get_treatment_opcode,
        @get_treatment_with_config_opcode,
        @get_treatments_opcode,
        @get_treatments_with_config_opcode,
        @split_opcode,
        @splits_opcode,
        @split_names_opcode,
        @track_opcode
      ]
    end
  end
end

defmodule Split.RPC.Message do
  @doc """
  Represents an IPC message to be sent to splitd.
  """
  use Split.RPC.MessageType

  @protocol_version 0x01
  @client_id "Splitd_Elixir-" <> to_string(Application.spec(:split, :vsn))

  @type opcode :: unquote(Enum.reduce(@message_type, &{:|, [], [&1, &2]}))
  @typep protocol_version :: unquote(@protocol_version)

  @derive [{Msgpax.Packer, fields: [:v, :o, :a]}]
  defstruct v: @protocol_version,
            o: nil,
            a: []

  @type t :: %__MODULE__{
          v: protocol_version(),
          o: opcode(),
          a: [term(), ...]
        }

  @doc """
  Builds a message to register a client in splitd.

  ## Examples

      iex> Split.RPC.Message.register()
      %Split.RPC.Message{v: 1, o: 0, a: ["123", "Splitd_Elixir-", 1]}
  """
  def register, do: %__MODULE__{o: @register_opcode, a: ["123", @client_id, 1]}

  @doc """
  Builds a message to get the treatment for a specific feature flag.

  ## Examples

      iex> Split.RPC.Message.get_treatment(
      ...>   user_key: "user_key",
      ...>   feature_name: "feature_name",
      ...>   bucketing_key: "bucketing_key"
      ...> )
      %Split.RPC.Message{a: ["user_key", "bucketing_key", "feature_name", %{}], o: 17, v: 1}

      iex> Split.RPC.Message.get_treatment(user_key: "user_key", feature_name: "feature_name")
      %Split.RPC.Message{a: ["user_key", nil, "feature_name", %{}], o: 17, v: 1}
  """
  def get_treatment(opts) do
    treatment_payload(opts, @get_treatment_opcode)
  end

  @doc """
  Builds a message to get the treatment for a specific feature flag with configuration.

  ## Examples

      iex> Split.RPC.Message.get_treatment_with_config(
      ...>   user_key: "user_key",
      ...>   feature_name: "feature_name",
      ...>   bucketing_key: "bucketing_key"
      ...> )
      %Split.RPC.Message{a: ["user_key", "bucketing_key", "feature_name", %{}], o: 19, v: 1}

      iex> Split.RPC.Message.get_treatment_with_config(
      ...>   user_key: "user_key",
      ...>   feature_name: "feature_name"
      ...> )
      %Split.RPC.Message{a: ["user_key", nil, "feature_name", %{}], o: 19, v: 1}
  """
  def get_treatment_with_config(opts) do
    treatment_payload(opts, @get_treatment_with_config_opcode)
  end

  @doc """
  Builds a message to get the treatments for multiple feature flags.

  ## Examples

      iex> Split.RPC.Message.get_treatments(
      ...>   user_key: "user_key",
      ...>   feature_names: ["feature_name1", "feature_name2"],
      ...>   bucketing_key: "bucketing_key"
      ...> )
      %Split.RPC.Message{
        a: ["user_key", "bucketing_key", ["feature_name1", "feature_name2"], %{}],
        o: 18,
        v: 1
      }

      iex> Split.RPC.Message.get_treatments(
      ...>   user_key: "user_key",
      ...>   feature_names: ["feature_name1", "feature_name2"]
      ...> )
      %Split.RPC.Message{a: ["user_key", nil, ["feature_name1", "feature_name2"], %{}], o: 18, v: 1}
  """
  def get_treatments(opts) do
    treatment_payload(opts, @get_treatments_opcode, multiple: true)
  end

  @doc """
  Builds a message to get the treatments for multiple feature flags with configuration.

  ## Examples

      iex> Split.RPC.Message.get_treatments_with_config(
      ...>   user_key: "user_key",
      ...>   feature_names: ["feature_name1", "feature_name2"],
      ...>   bucketing_key: "bucketing_key"
      ...> )
      %Split.RPC.Message{
        a: ["user_key", "bucketing_key", ["feature_name1", "feature_name2"], %{}],
        o: 20,
        v: 1
      }

      iex> Split.RPC.Message.get_treatments_with_config(
      ...>   user_key: "user_key",
      ...>   feature_names: ["feature_name1", "feature_name2"]
      ...> )
      %Split.RPC.Message{
        a: ["user_key", nil, ["feature_name1", "feature_name2"], %{}],
        o: 20,
        v: 1
      }
  """
  def get_treatments_with_config(opts) do
    treatment_payload(opts, @get_treatments_with_config_opcode, multiple: true)
  end

  @doc """
  Builds a message to return information about an specific split (feature flag).

  ## Examples

      iex> Split.RPC.Message.split("my_feature")
      %Split.RPC.Message{v: 1, o: 161, a: ["my_feature"]}
  """
  def split(split_name), do: %__MODULE__{o: @split_opcode, a: [split_name]}

  @doc """
  Builds a message to return information about all the splits (feature flags) currently available in splitd.

  ## Examples

      iex> Split.RPC.Message.splits()
      %Split.RPC.Message{v: 1, o: 162, a: []}
  """
  def splits(), do: %__MODULE__{o: @splits_opcode}

  @doc """
  Builds a message to return the names of all the splits (feature flags) currently available in splitd.

  ## Examples

      iex> Split.RPC.Message.split_names()
      %Split.RPC.Message{v: 1, o: 160, a: []}
  """
  def split_names(), do: %__MODULE__{o: @split_names_opcode}

  @doc """
  Message that creates and event and sends it to splitd so that it’s queued and submitted to Split.io.

  ## Examples

      iex> Split.RPC.Message.track("user_key", "traffic_type", "my_event", 1.5, %{foo: "bar"})
      %Split.RPC.Message{
        v: 1,
        o: 128,
        a: ["user_key", "traffic_type", "my_event", 1.5, %{foo: "bar"}]
      }

      iex> Split.RPC.Message.track("user_key", "traffic_type", "my_event")
      %Split.RPC.Message{v: 1, o: 128, a: ["user_key", "traffic_type", "my_event", nil, %{}]}
  """
  def track(user_key, traffic_type, event_type, value \\ nil, properties \\ %{}) do
    %__MODULE__{
      o: @track_opcode,
      a: [user_key, traffic_type, event_type, value, properties]
    }
  end

  defp treatment_payload(data, opcode, opts \\ []) do
    features_key =
      if Keyword.get(opts, :multiple, false), do: :feature_names, else: :feature_name

    user_key = Keyword.fetch!(data, :user_key)
    feature_name = Keyword.fetch!(data, features_key)
    bucketing_key = Keyword.get(data, :bucketing_key, nil)
    attributes = Keyword.get(data, :attributes, %{})

    %__MODULE__{
      o: opcode,
      a: [
        user_key,
        bucketing_key,
        feature_name,
        attributes
      ]
    }
  end
end
