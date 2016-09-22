defmodule ActiveJobsSupervisor do
  use Supervisor

  def start_link(:ok) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      worker(Job.Otp, [], restart: :temporary, shutdown: 4_000),
    ]
    supervise(children, strategy: :simple_one_for_one)
  end
end
