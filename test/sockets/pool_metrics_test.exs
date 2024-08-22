defmodule Split.Sockets.PoolMetricsTest do
  use ExUnit.Case

  alias Split.Sockets.PoolMetrics

  describe "init/2" do
    test "initializes atomics ref and puts it into a persistent term" do
      {:ok, ref} = PoolMetrics.init(:test_pool_name, 10)
      assert :persistent_term.get({PoolMetrics, :metrics, :test_pool_name}) == ref
    end
  end

  describe "get/1" do
    test "gets the metrics for a pool" do
      {:ok, _ref} = PoolMetrics.init(:test_pool_name, 10)

      assert PoolMetrics.get(:test_pool_name) ==
               {:ok,
                %PoolMetrics{pool_size: 10, connections_available: 10, connections_in_use: 0}}
    end

    test "returns an error if the pool does not exist" do
      assert PoolMetrics.get(:non_existent_pool) == {:error, :not_found}
    end
  end

  describe "update/2" do
    test "updates a valid metric value" do
      {:ok, ref} = PoolMetrics.init(:test_pool_name, 10)
      PoolMetrics.update(ref, {:connections_in_use, 5})

      assert PoolMetrics.get(:test_pool_name) ==
               {:ok, %PoolMetrics{pool_size: 10, connections_available: 5, connections_in_use: 5}}
    end

    test "does not update the metric value if the ref is nil" do
      assert PoolMetrics.update(nil, {:pool_size, 20}) == :ok
    end

    test "does not update the metric value if the metric is not in the list of valid metrics" do
      {:ok, ref} = PoolMetrics.init(:test_pool_name, 10)
      assert PoolMetrics.update(ref, {:connections_available, 20}) == :ok

      assert PoolMetrics.get(:test_pool_name) ==
               {:ok,
                %PoolMetrics{pool_size: 10, connections_available: 10, connections_in_use: 0}}
    end
  end
end
