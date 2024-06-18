defmodule Split do
  @moduledoc """
  Documentation for `Split`.
  """
  alias Split.Sockets.Pool
  alias Split.Telemetry
  alias Split.Treatment

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
          {:ok, Treatment.t()} | {:error, map()}
  def get_treatment(user_key, feature_name, bucketing_key \\ nil, attributes \\ %{}) do
    execute_treatment_rpc(
      user_key,
      feature_name,
      bucketing_key,
      attributes,
      Split.RPCs.GetTreatment,
      :get_treatment
    )
  end

  @spec get_treatment_with_config(String.t(), String.t(), String.t() | nil, map() | nil) ::
          {:ok, map()} | {:error, map()}
  def get_treatment_with_config(user_key, feature_name, bucketing_key \\ nil, attributes \\ %{}) do
    execute_treatment_rpc(
      user_key,
      feature_name,
      bucketing_key,
      attributes,
      Split.RPCs.GetTreatmentWithConfig,
      :get_treatment_with_config
    )
  end

  @spec get_treatments(String.t(), [String.t()], String.t() | nil, map() | nil) ::
          {:ok, map()} | {:error, map()}
  def get_treatments(user_key, feature_names, bucketing_key \\ nil, attributes \\ %{}) do
    execute_treatment_rpc(
      user_key,
      feature_names,
      bucketing_key,
      attributes,
      Split.RPCs.GetTreatments,
      :get_treatments
    )
  end

  @spec get_treatments_with_config(String.t(), [String.t()], String.t() | nil, map() | nil) ::
          {:ok, map()} | {:error, map()}
  def get_treatments_with_config(user_key, feature_names, bucketing_key \\ nil, attributes \\ %{}) do
    execute_treatment_rpc(
      user_key,
      feature_names,
      bucketing_key,
      attributes,
      Split.RPCs.GetTreatmentsWithConfig,
      :get_treatments_with_config
    )
  end

  @spec get_treatments_with_config(String.t(), [String.t()], String.t() | nil, map() | nil) ::
          {:ok, map()} | {:error, map()}
  def track(user_key, traffic_type, event_type, value \\ nil, properties \\ %{}) do
    user_key
    |> Split.RPCs.Track.build(traffic_type, event_type, value, properties)
    |> Pool.send_message()
    |> Split.RPCs.Track.parse_response()
  end

  def split_names do
    execute_management_rpc(Split.RPCs.SplitNames, :split_names)
  end

  @spec split(String.t()) :: {:ok, Split.t()} | {:error, map()}
  def split(name) do
    name
    |> Split.RPCs.Split.build()
    |> Pool.send_message()
    |> Split.RPCs.Split.parse_response()
  end

  @spec splits() :: {:ok, [Split.t()]} | {:error, map()}
  def splits do
    execute_management_rpc(Split.RPCs.Splits, :splits)
  end

  defp execute_management_rpc(rpc, rpc_name) do
    :telemetry.span(
      [:split, :management],
      %{
        method: rpc_name
      },
      fn ->
        rpc.build()
        |> Pool.send_message()
        |> rpc.parse_response()
        |> then(&{&1, %{}})
      end
    )
  end

  defp execute_treatment_rpc(user_key, feature_name, bucketing_key, attributes, rpc, rpc_name) do
    :telemetry.span(
      [:split, :client],
      %{
        method: rpc_name,
        user_key: user_key,
        feature_name: feature_name,
        bucketing_key: bucketing_key,
        attributes: attributes
      },
      fn ->
        user_key
        |> rpc.build(feature_name, bucketing_key, attributes)
        |> Pool.send_message()
        |> rpc.parse_response()
        |> case do
          {:ok, treatments?} ->
            case is_list(treatments?) do
              true ->
                Enum.each(treatments?, fn {feature_name, treatment} ->
                  Telemetry.send_impression(user_key, feature_name, treatment)
                end)

                {:ok, treatments?}

              false ->
                Telemetry.send_impression(user_key, feature_name, treatments?)
                {:ok, treatments?}
            end

          {:error, response} ->
            {:error, response}
        end
        |> then(fn
          {:ok, treatment} = response -> {response, %{treatment: treatment}}
          {:error, _} = response -> {response, %{}}
        end)
      end
    )
  end
end
