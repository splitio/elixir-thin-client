defmodule Split.RPC do
  alias Split.Sockets.Pool
  alias Split.Telemetry
  alias Split.Treatment

  @callback build(Keyword.t()) :: map()
  @callback parse_response(map(), Keyword.t()) :: {:ok, map()} | {:error, map()}

  def execute_treatment_rpc(rpc, opts) do
    sorted_attribute_binary = opts[:attributes] |> Enum.sort() |> :erlang.term_to_binary()
    user_key = opts[:user_key]
    feature_name = opts[:feature_name]

    cache_key =
      "#{user_key}#{feature_name}#{sorted_attribute_binary}" |> :erlang.crc32()

    case Process.get("split_sdk_cache-#{cache_key}") do
      nil ->
        case execute_rpc(rpc, opts) do
          {:ok, treatment} ->
            Process.put("split_sdk_cache-#{cache_key}", treatment)
            send_impression(user_key, feature_name, treatment)
            {:ok, treatment}

          {:error, response} ->
            {:error, response}
        end

      treatment ->
        {:ok, treatment}
    end
  end

  def execute_rpc(rpc, opts) do
    opts
    |> rpc.build()
    |> Pool.send_message()
    |> rpc.parse_response(opts)
  end

  def send_impression(user_key, feature_name, %Treatment{} = treatment) do
    Telemetry.send_impression(user_key, feature_name, treatment)
  end

  def send_impression(user_key, _feature_name, treatment) when is_map(treatment) do
    Enum.each(treatment, fn {feature_name, treatment} ->
      Telemetry.send_impression(user_key, feature_name, treatment)
    end)
  end
end
