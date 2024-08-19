defmodule Split.Test.MockSplitdServer do
  use Supervisor

  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  @impl Supervisor
  def init(opts \\ []) do
    children = [
      {Task.Supervisor, strategy: :one_for_one, name: TestTaskSupervisor},
      {Task, fn -> accept(opts) end}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def accept(opts) do
    socket_path = Keyword.get(opts, :socket_path)

    {:ok, socket} =
      :gen_tcp.listen(0,
        active: false,
        packet: :raw,
        reuseaddr: true,
        ifaddr: {:local, socket_path}
      )

    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)

    {:ok, _pid} =
      Task.Supervisor.start_child(TestTaskSupervisor, __MODULE__, :serve, [
        client
      ])

    loop_acceptor(socket)
  end

  def serve(client) do
    case :gen_tcp.recv(client, 0) do
      {:ok, data} ->
        payload = Enum.slice(data, 4..-1//1)
        unpacked_payload = Msgpax.unpack!(payload)

        response = build_response(Map.get(unpacked_payload, "o"))
        packed_message = Msgpax.pack!(response, iodata: false)

        payload =
          <<byte_size(packed_message)::integer-unsigned-little-size(32), packed_message::binary>>

        :ok = :gen_tcp.send(client, payload)
        serve(client)

      _other ->
        serve(client)
    end
  end

  defp build_response(0), do: %{"s" => 1}
  defp build_response(17), do: %{"s" => 1, "p" => %{"t" => "on"}}
  defp build_response(19), do: %{"s" => 1, "p" => %{"t" => "on", "c" => %{"foo" => "bar"}}}
  defp build_response(18), do: %{"s" => 1, "p" => %{"r" => [%{"t" => "on"}]}}

  defp build_response(20) do
    %{"s" => 1, "p" => %{"r" => [%{"t" => "on", "c" => %{"foo" => "bar"}}]}}
  end

  defp build_response(128), do: %{"s" => 1, "p" => %{"s" => true}}
  defp build_response(160), do: %{"s" => 1, "p" => %{"n" => ["ethan_test"]}}

  defp build_response(161) do
    %{
      "s" => 1,
      "p" => %{
        "n" => "test-split",
        "t" => "traffic_type",
        "k" => false,
        "s" => ["on", "off"],
        "c" => 12345,
        "f" => %{"on" => "foo"},
        "d" => "default_treatment",
        "e" => ["flag_set"]
      }
    }
  end

  defp build_response(162) do
    %{
      "s" => 1,
      "p" => %{
        "s" => [
          %{
            "n" => "test-split",
            "t" => "traffic_type",
            "k" => false,
            "s" => ["on", "off"],
            "c" => 12345,
            "f" => %{"on" => "foo"},
            "d" => "default_treatment",
            "e" => ["flag_set"]
          }
        ]
      }
    }
  end
end
