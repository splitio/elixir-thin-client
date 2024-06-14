defmodule Splitd do
  use GenServer

  require Logger

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Process.flag(:trap_exit, true)
    port = Port.open({:spawn_executable, "/Users/egunderson/projects/splitd/splitd"}, [])
    {:ok, port}
  end

  def handle_info({_port, {:data, data}}, state) do
    Logger.debug(data)
    {:noreply, state}
  end

  def handle_info({:EXIT, _pid, reason}, state) do
    Logger.debug("Port died: #{inspect(reason)}")
    {:stop, :normal, state}
  end
end
