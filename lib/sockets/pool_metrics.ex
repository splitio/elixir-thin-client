defmodule Split.Sockets.PoolMetrics do
  @moduledoc """
  This module provides a way to store and update pool utilization metrics.
  """
  @type t :: %__MODULE__{}

  defstruct [
    :pool_size,
    :connections_available,
    :connections_in_use
  ]

  @metrics [
    :pool_size,
    :connections_in_use
  ]

  def init(pool_name, pool_size) do
    ref = :atomics.new(length(@metrics), signed: false)
    :atomics.add(ref, metric_index(:pool_size), pool_size)

    :persistent_term.put({__MODULE__, :metrics, pool_name}, ref)
    {:ok, ref}
  end

  @spec update(:atomics.atomics_ref(), {atom(), integer()}) :: :ok
  def update(ref, {metric, val}) when not is_nil(ref) and metric in @metrics do
    :atomics.add(ref, metric_index(metric), val)
  end

  def update(_ref, _metric), do: :ok

  @spec get(module()) :: {:ok, t()} | {:error, :not_found}
  def get(pool_name) do
    case :persistent_term.get({__MODULE__, :metrics, pool_name}, nil) do
      nil -> {:error, :not_found}
      ref -> get_metrics(ref)
    end
  end

  defp get_metrics(ref) do
    %{
      pool_size: pool_size,
      connections_in_use: connections_in_use
    } =
      @metrics
      |> Enum.with_index()
      |> Enum.map(fn {metric, i} -> {metric, :atomics.get(ref, i + 1)} end)
      |> Map.new()

    {:ok,
     %__MODULE__{
       pool_size: pool_size,
       connections_available: pool_size - connections_in_use,
       connections_in_use: connections_in_use
     }}
  end

  defp metric_index(metric) do
    Enum.find_index(@metrics, &(&1 == metric)) + 1
  end
end
