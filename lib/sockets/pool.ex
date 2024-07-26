defmodule Split.Sockets.Pool do
  require Logger

  @behaviour NimblePool

  alias Split.Sockets.Conn

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  def start_link(opts) do
    NimblePool.start_link(
      worker: {__MODULE__, opts},
      pool_size: Keyword.get(opts, :pool_size, 10),
      lazy: false,
      worker_idle_timeout: :timer.minutes(30)
    )
  end

  def send_message(message, checkout_timeout \\ 5_000) do
    NimblePool.checkout!(
      __MODULE__,
      :checkout,
      fn caller, {state, conn, _idle_time} ->
        with true <- Conn.is_open?(conn),
             {:ok, conn} <- Conn.connect(conn),
             {:ok, conn, resp} <- Conn.send_message(conn, message) do
          {{:ok, resp}, transfer_if_open(conn, state, caller)}
        else
          false ->
            {{:error, :closed}, :closed}

          {:error, conn, error} ->
            {{:error, error}, transfer_if_open(conn, state, caller)}
        end
      end,
      checkout_timeout
    )
  end

  defp transfer_if_open(conn, state, {pid, _} = caller) do
    if Conn.is_open?(conn) do
      if state == :fresh do
        NimblePool.update(caller, conn)
        {:ok, ^conn} = Conn.transfer_ownership(conn, pid)
      else
        {:ok, conn}
      end
    else
      :closed
    end
  end

  @impl NimblePool
  def init_pool(%{socket_path: socket_path} = opts) do
    Logger.error("""
    Failed to start Split SDK socket pool. The socket was not found at #{socket_path}.

    This is likely because the Splitd daemon is not running. Please start the daemon and try again.
    """)

    {:ok, opts}
  end

  @impl NimblePool
  def init_worker(%{socket_path: socket_path} = opts) do
    {:ok, Conn.new(socket_path, opts), opts}
  end

  @impl NimblePool
  def handle_checkout(:checkout, _from, %{socket: nil} = conn, pool_state) do
    idle_time = System.monotonic_time() - conn.last_checkin
    {:ok, {:fresh, conn, idle_time}, conn, pool_state}
  end

  def handle_checkout(:checkout, _from, conn, pool_state) do
    idle_time = System.monotonic_time() - conn.last_checkin

    if Conn.is_open?(conn) do
      {:ok, {:reused, conn, idle_time}, conn, pool_state}
    else
      {:remove, :closed, pool_state}
    end
  end

  @impl NimblePool
  def handle_checkin(checkin, _from, _old_conn, pool_state) do
    with {:ok, conn} <- checkin,
         true <- Conn.is_open?(conn) do
      {:ok, %{conn | last_checkin: System.monotonic_time()}, pool_state}
    else
      _ ->
        Logger.debug("Error checking in socket.. removing: #{inspect(checkin)}")
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
end
