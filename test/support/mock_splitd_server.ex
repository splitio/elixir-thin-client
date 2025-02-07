defmodule Split.Test.MockSplitdServer do
  use Supervisor

  require Logger

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)

    Supervisor.start_link(__MODULE__, opts, name: name)
  end

  @impl Supervisor
  def init(opts \\ []) do
    socket_path = Keyword.get(opts, :socket_path)
    name = Keyword.get(opts, :name, __MODULE__)
    opts = Keyword.put_new(opts, :name, name)

    File.rm(socket_path)

    children = [
      {Task.Supervisor, strategy: :one_for_one, name: :"#{name}-task-supervisor"},
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

    loop_acceptor(socket, opts)
  end

  def wait_until_listening(socket_path) do
    if File.exists?(socket_path) do
      :ok
    else
      Process.sleep(1)
      wait_until_listening(socket_path)
    end
  end

  defp loop_acceptor(socket, opts) do
    {:ok, client} = :gen_tcp.accept(socket)

    {:ok, _pid} =
      Task.Supervisor.start_child(:"#{opts[:name]}-task-supervisor", __MODULE__, :serve, [
        client
      ])

    loop_acceptor(socket, opts)
  end

  def serve(client) do
    case :gen_tcp.recv(client, 0) do
      {:ok, data} ->
        payload = Enum.slice(data, 4..-1//1)
        unpacked_payload = Msgpax.unpack!(payload)

        case build_response(Map.get(unpacked_payload, "o")) do
          response when is_map(response) ->
            packed_message = Msgpax.pack!(response, iodata: false)

            payload =
              <<byte_size(packed_message)::integer-unsigned-little-size(32),
                packed_message::binary>>

            :ok = :gen_tcp.send(client, payload)

          {:error, :disconnect} ->
            :gen_tcp.shutdown(client, :read)

          {:error, :wait} ->
            # Wait for a bit before sending a basic sucessful response
            Process.sleep(2)

            resp = Msgpax.pack!(%{"s" => 1}, iodata: false)

            payload = <<byte_size(resp)::integer-unsigned-little-size(32), resp::binary>>

            :ok = :gen_tcp.send(client, payload)
        end

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

  defp build_response(21), do: %{"s" => 1, "p" => %{"r" => %{"emi_test" => %{"t" => "on"}}}}

  defp build_response(22) do
    %{"s" => 1, "p" => %{"r" => %{"emi_test" => %{"t" => "on", "c" => %{"foo" => "bar"}}}}}
  end

  defp build_response(23), do: %{"s" => 1, "p" => %{"r" => %{"emi_test" => %{"t" => "on"}}}}

  defp build_response(24) do
    %{"s" => 1, "p" => %{"r" => %{"emi_test" => %{"t" => "on", "c" => %{"foo" => "bar"}}}}}
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

  defp build_response("disconnect"), do: {:error, :disconnect}
  defp build_response("wait"), do: {:error, :wait}
end
