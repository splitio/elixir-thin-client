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
      # TODO: make this configurable
      # pool_size: 100,
      lazy: false,
      worker_idle_timeout: 60_000
    )
  end

  def send_message(message) do
    NimblePool.checkout!(
      __MODULE__,
      :checkout,
      fn caller, {state, conn, _idle_time} ->
        with {:ok, conn} <- Conn.connect(conn),
             {:ok, conn, resp} <- Conn.send_message(conn, message) do
          {{:ok, resp}, transfer_if_open(conn, state, caller)}
        else
          {:error, conn, error} ->
            {{:error, error}, transfer_if_open(conn, state, caller)}
        end
      end,
      5_000
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
    if File.exists?(socket_path) do
      {:ok, opts}
    else
      {:stop, :socket_not_found}
    end
  end

  @impl NimblePool
  def init_worker(%{socket_path: socket_path} = pool_state) do
    {:ok, Conn.new(socket_path, []), pool_state}
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
