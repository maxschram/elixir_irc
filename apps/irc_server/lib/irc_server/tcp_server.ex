defmodule IrcServer.TcpServer do
  require Logger

  def accept(port) do
    {:ok, socket} = :gen_tcp.listen(port,
                      [:binary, packet: :line, active: false, reuseaddr: true])
    {:ok, irc} = IrcServer.IrcServer.start_link
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
    |> run_commands(socket)

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

  defp run_commands({prefix, "USER", params}, socket) do
  end

  defp run_commands({"USER", params}, socket) do
    send_response(":localhost 001 mbs :Welcome\r\n", socket)
  end

  defp run_commands({"JOIN", [channel]}, socket) do
    IrcServer.IrcServer.join({self, socket, String.strip(channel)})
  end

  defp run_commands({"PRIVMSG", [channel, message]}, socket) do
    IrcServer.IrcServer.privmsg("mbs", channel, message)
  end

  defp run_commands({"PING", [hostname]}) do
    send_response("PONG #{hostname}", socket)
  end

  defp run_commands(args, socket) do
    :empty
  end

  defp read_line(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    Logger.info "Received data from client: #{data}"
    data
  end

  def send_response(response = :empty, socket) do end

  def send_response(response, socket) do
    # Logger.debug "Sending #{inspect response} to #{inspect socket}"
    :gen_tcp.send(socket, response)
  end
end
