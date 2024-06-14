defmodule Split.Sockets.Supervisor do
  use GenServer

  alias Split.Sockets.Pool

  def init(init_arg) do
    {:ok, init_arg}
  end

  def start_link(opts) do
    # opts = Keyword.merge([name: Pool], opts)
    # child = {NimblePool, worker: {Pool, opts}, name: Pool, lazy: false}
    Supervisor.start_link([Pool], opts)
  end
end
