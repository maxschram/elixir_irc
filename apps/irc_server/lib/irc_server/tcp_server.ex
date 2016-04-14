defmodule IrcServer.TcpServer do
  require Logger

  def accept(port) do
    {:ok, socket} = :gen_tcp.listen(port,
                      [:binary, packet: :line, active: false, reuseaddr: true])
    Logger.info "Accepting conections on port #{port}"
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(IrcServer.TaskSupervisor,
                                            fn -> serve(client) end)

    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  defp serve(socket) do
    socket
    |> read_line
    |> parse_commands
    |> run_commands
    |> send_response(socket)

    serve(socket)
  end

  defp parse_commands(line) do
    lines = String.split(line, " ")
    case lines do
      [":" <> prefix, command | params] ->
        Logger.debug "Prefix: #{prefix} Command: #{command} Params:
          #{Enum.join(params, ", ")}"
        {prefix, command, params}
      [command | params] ->
        Logger.debug "Command: #{command} Params: #{Enum.join(params, ", ")}"
        {command, params}
    end
  end

  defp run_commands({prefix, "USER", params}) do
  end

  defp run_commands({"USER", params}) do
    "Welcome\n\r"
  end

  defp run_commands(args) do
    :empty
  end

  defp read_line(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    Logger.info "Received data from client: #{data}"
    data
  end

  defp send_response(response = :empty, socket) do end

  defp send_response(response, socket) do
    # if String.starts_with?(line, "USER") do
    #   :ok = :gen_tcp.send(socket, ":localhost 001 mbs :Welcome\n\r")
    #   :ok = :gen_tcp.send(socket, "PING :lkasjdflklasdjflkj")
    # end
    :gen_tcp.send(socket, ":localhost 001 mbs :Welcome\n\r")
  end
end
