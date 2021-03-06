defmodule IrcServer do
  use Application

  def start(_type, _args) do
    :observer.start()
    import Supervisor.Spec
    children = [
      supervisor(Task.Supervisor, [[name: IrcServer.TaskSupervisor]]),
      worker(Task, [IrcServer.TcpServer, :accept, [6667]])
    ]

    opts = [strategy: :one_for_one, name: IrcServer.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
