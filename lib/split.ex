defmodule Split do
  @moduledoc """
  Documentation for `Split`.
  """
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
    metadata = %{
      rpc_call: Message.opcode_to_rpc_name(request.o)
    }

    :telemetry.span([:split, :rpc], metadata, fn ->
      request
      |> Pool.send_message(opts)
      |> ResponseParser.parse_response(request)
      |> case do
        {:ok, data} = response ->
          {response, Map.put(metadata, :response, inspect(data))}

        :ok ->
          {:ok, metadata}

        {:error, reason} = error ->
          {error, Map.put(metadata, :error, reason)}
      end
    end)
  end
end
