defmodule Split.Sockets.Supervisor do
  use GenServer

  alias Split.Sockets.Pool

  def init(init_arg) do
    {:ok, init_arg}
  end

  def start_link(opts) do
    child = {Pool, opts}
    Supervisor.start_link([child], strategy: :one_for_one)
  end
end
