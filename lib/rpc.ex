defmodule Split.RPC do
  alias Split.Sockets.Pool
  alias Split.Telemetry
  alias Split.Treatment

  @callback build(Keyword.t()) :: map()
  @callback parse_response({:ok, map()}, Keyword.t()) :: {:ok, map()} | {:error, term()}

  @spec execute_treatment_rpc(module(), Keyword.t()) :: {:ok, map()} | {:error, map()}
  def execute_treatment_rpc(rpc, opts) do
    :telemetry.span([:split, :function], %{rpc: inspect(rpc)}, fn ->
      user_key = opts[:user_key]
      feature_name = opts[:feature_name]

      case execute_rpc(rpc, opts) do
        {:ok, treatment} ->
          send_impression(user_key, feature_name, treatment)
          {:ok, treatment}

        {:error, response} ->
          {:error, response}
      end
      |> then(fn
        {:ok, treatment} = response ->
          {response, %{treatment: treatment}}

        {:error, _reason} = response ->
          {response, %{treatment: nil}}
      end)
    end)
  end

  def generate_cache_key(opts) do
    sorted_attribute_binary = opts[:attributes] |> Enum.sort() |> :erlang.term_to_binary()
    user_key = opts[:user_key]
    feature_name = opts[:feature_name]

    "#{user_key}#{feature_name}#{sorted_attribute_binary}"
    |> :erlang.crc32()
    |> then(&"split_sdk_cache-#{&1}")
  end

  def execute_rpc(rpc, opts) do
    :telemetry.span([:split, :rpc], %{rpc: inspect(rpc)}, fn ->
      opts
      |> rpc.build()
      |> Pool.send_message()
      |> rpc.parse_response(opts)
      |> then(fn {status, _} = response ->
        {response, %{execution_status: status}}
      end)
    end)
  end

  @spec send_impression(String.t(), String.t(), Treatment.t()) :: :ok
  def send_impression(user_key, feature_name, %Treatment{} = treatment) do
    Telemetry.send_impression(user_key, feature_name, treatment)
  end

  def send_impression(user_key, _feature_name, treatment) when is_map(treatment) do
    Enum.each(treatment, fn {feature_name, treatment} ->
      Telemetry.send_impression(user_key, feature_name, treatment)
    end)
  end
end
