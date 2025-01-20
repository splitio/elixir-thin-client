defmodule Split.Sockets.Pool do
  require Logger

  @behaviour NimblePool

  alias Split.Sockets.Conn
  alias Split.Sockets.PoolMetrics
  alias Split.Telemetry

  @default_checkout_timeout 1000

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  def start_link(opts) when is_list(opts) do
    start_link(Map.new(opts))
  end

  def start_link(opts) when is_map(opts) do
    socket_path = Map.get(opts, :socket_path, "/var/run/splitd.sock")
    fallback_enabled = Map.get(opts, :fallback_enabled, false)
    :persistent_term.put(:splitd_fallback_enabled, fallback_enabled)

    pool_name = Map.get(opts, :pool_name, __MODULE__)
    pool_size = Map.get(opts, :pool_size, System.schedulers_online())

    opts =
      opts
      |> Map.put_new(:socket_path, socket_path)
      |> Map.put_new(:fallback_enabled, fallback_enabled)
      |> Map.put_new(:pool_size, pool_size)
      |> Map.put_new(:pool_name, pool_name)

    NimblePool.start_link(
      worker: {__MODULE__, opts},
      pool_size: pool_size,
      lazy: false,
      worker_idle_timeout: :timer.minutes(30),
      name: pool_name
    )
  end

  def send_message(message, opts \\ []) do
    pool_name = Keyword.get(opts, :pool_name, __MODULE__)
    checkout_timeout = Keyword.get(opts, :checkout_timeout, @default_checkout_timeout)

    metadata = %{
      pool_name: pool_name,
      message: message
    }

    queue_start = Telemetry.start(:queue, metadata)

    try do
      NimblePool.checkout!(
        pool_name,
        :checkout,
        fn caller, {state, conn} ->
          Telemetry.stop(queue_start, metadata)

          with {:ok, conn} <- Conn.connect(conn),
               {:ok, conn, resp} <- Conn.send_message(conn, message) do
            {{:ok, resp}, update_if_open(conn, state, caller)}
          else
            {:error, conn, error} ->
              {{:error, error}, update_if_open(conn, state, caller)}
          end
        end,
        checkout_timeout
      )
    catch
      :exit, reason ->
        Telemetry.exception(queue_start, :exit, reason, __STACKTRACE__)

        case reason do
          {:timeout, {NimblePool, :checkout, _affected_pids}} ->
            Logger.error("""
            The Split SDK was unable to provide a connection within the timeout (#{checkout_timeout} milliseconds) \
            due to excess queuing for connections. Consider adjusting the pool size, checkout_timeout or reducing the \
            rate of requests if it is possible that the splitd service is unable to keep up \
            with the current rate.
            """)

            {:error, reason}

          _ ->
            {:error, reason}
        end
    end
  end

  defp update_if_open(conn, state, caller) do
    if Conn.is_open?(conn) do
      if state == :new do
        NimblePool.update(caller, conn)
        {:ok, conn}
      else
        {:ok, conn}
      end
    else
      :closed
    end
  end

  @impl NimblePool
  def init_pool(%{socket_path: socket_path} = opts) do
    unless File.exists?(socket_path) do
      Logger.error("""
      The Split Daemon (splitd) socket was not found at #{socket_path}.

      This is likely because the Splitd daemon is not running.
      """)
    end

    {:ok, metrics_ref} = PoolMetrics.init(opts[:pool_name], opts[:pool_size])

    {:ok, {opts, metrics_ref}}
  end

  @impl NimblePool
  def init_worker({%{socket_path: socket_path} = opts, _metrics_ref} = pool_state) do
    {:ok, Conn.new(socket_path, opts), pool_state}
  end

  @impl NimblePool
  def handle_checkout(:checkout, _from, %{socket: nil} = conn, {_opts, metrics_ref} = pool_state) do
    PoolMetrics.update(metrics_ref, {:connections_in_use, 1})
    {:ok, {:new, conn}, conn, pool_state}
  end

  def handle_checkout(:checkout, _from, conn, {_opts, metrics_ref} = pool_state) do
    if Conn.is_open?(conn) do
      PoolMetrics.update(metrics_ref, {:connections_in_use, 1})
      {:ok, {:reused, conn}, conn, pool_state}
    else
      {:remove, :closed, pool_state}
    end
  end

  @impl NimblePool
  def handle_checkin(checkin, _from, _old_conn, {_opts, metrics_ref} = pool_state) do
    PoolMetrics.update(metrics_ref, {:connections_in_use, -1})

    with {:ok, conn} <- checkin,
         true <- Conn.is_open?(conn) do
      {:ok, conn, pool_state}
    else
      _ ->
        Logger.debug(
          "Error checking in socket #{inspect(checkin)} to the pool. Socket is closed."
        )

        {:remove, :closed, pool_state}
    end
  end

  @impl NimblePool
  def handle_update(new_conn, _old_conn, pool_state) do
    {:ok, new_conn, pool_state}
  end

  @impl NimblePool
  def terminate_worker(reason, conn, pool_state) do
    Logger.debug("Terminating worker with reason: #{inspect(reason)}")
    Conn.disconnect(conn)
    {:ok, pool_state}
  end

  @impl NimblePool
  def handle_cancelled(:checked_out, {_opts, metrics_ref} = _pool_state) do
    PoolMetrics.update(metrics_ref, {:connections_in_use, -1})
    :ok
  end

  def handle_cancelled(:queued, _pool_state), do: :ok

  @impl NimblePool
  def handle_ping(_conn, _pool_state) do
    {:stop, :idle_timeout}
  end
end
