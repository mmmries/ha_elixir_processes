defmodule Job.Otp do
  use GenServer
  require Logger

  # public interface
  def start(job_id) do
    case :gproc.lookup_pids({:p, :g, job_id}) do
      [] -> Supervisor.start_child(ActiveJobsSupervisor, [%{job_id: job_id}])
      _ -> {:error, :job_already_started}
    end
  end

  def check_results(job_id) do
    case :gproc.lookup_pids({:p, :g, job_id}) do
      [] -> {:error, :no_such_job}
      [pid | _] -> GenServer.call(pid, :check_results)
    end
  end

  def start_link(map) do
    GenServer.start_link(__MODULE__, map)
  end

  def init(map) do
    Process.flag(:trap_exit, true)
    :timer.send_after(30_000, :cleanup)
    kickoff_hard_work(map)
    :gproc.reg({:p, :g, map.job_id})
    {:ok, map}
  end

  def handle_call(:check_results, _from, state) do
    {:reply, Map.get(state, :results), state}
  end

  def handle_info(:cleanup, state) do
    {:stop, :normal, state}
  end
  def handle_info({:got_results, results}, state) do
    {:noreply, Map.put(state, :results, results)}
  end
  def handle_info(other, events) do
    Logger.error "#{__MODULE__} unpexected message received: #{inspect other}"
    {:noreply, events}
  end

  def terminate(:shutdown, state) do
    Logger.info "#{__MODULE__} shutting down, can I have someone else take over?"
    case Node.list do
      [] -> :ok # can't move job to another node
      list ->
        node = list |> Enum.shuffle |> List.first
        :rpc.call(node, Supervisor, :start_child, [ActiveJobsSupervisor, [state]])
        :ok
    end
  end
  def terminate(_, _state) do
    :ok
  end

  defp kickoff_hard_work(%{results: _}), do: :no_op
  defp kickoff_hard_work(%{job_id: job_id}), do: :timer.send_after(3_000, {:got_results, "results of #{job_id}"})
end
