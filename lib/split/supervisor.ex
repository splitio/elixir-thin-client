defmodule Split.Supervisor do
  @moduledoc """
  The supervisor for the Split SDK.
  """

  use GenServer

  alias Split.Sockets.Pool

  def init(init_arg) do
    {:ok, init_arg}
  end

  @spec start_link(Split.options()) :: Supervisor.on_start()
  def start_link(opts) do
    child = {Pool, opts}
    Supervisor.start_link([child], strategy: :one_for_one)
  end
end
