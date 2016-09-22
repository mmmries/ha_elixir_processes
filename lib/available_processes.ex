defmodule AvailableProcesses do
  use Application

  def start(_mode, _args) do
    import Supervisor.Spec

    children = [
      supervisor(ActiveJobsSupervisor, [:ok], shutdown: 10_000),
    ]
    Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
  end
end
