defmodule IrcServer.IrcServer do
  require Logger
  use GenServer

  def start_link do
    {:ok, _pid} = GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def privmsg(source, channel, message) do
    GenServer.cast __MODULE__, {:privmsg, source, channel, message}
  end

  def join(connection) do
    GenServer.call __MODULE__, {:join, connection}
  end

  def handle_cast({:privmsg, source, channel, message}, connections) do
    Enum.each connections, fn connection ->
      # Logger.debug "Sending #{inspect message} to #{inspect connection}"
      IrcServer.TcpServer.send_response(":#{source} PRIVMSG #{channel} #{message}", elem(connection, 1))
    end
    {:noreply, connections}
  end

  def handle_call({:join, connection}, _from, connections) do
    { :reply, :ok, [connection | connections] }
  end
end
