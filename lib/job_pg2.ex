defmodule Job.Pg2 do
  use GenServer

  def start(job_id) when is_binary(job_id) do
    channel = pg2_channel(job_id)
    Node.list |> Enum.each( &(
      {:ok, _pid} = :rpc.call(&1, GenServer, :start, [__MODULE__, job_id, [name: channel]])
    ))
    {:ok, :all_started}
  end

  def update(job_id, event) do
    channel = pg2_channel(job_id)
    :pg2.create(channel)
    for pid <- :pg2.get_members(channel) do
      send(pid, {:update, event})
    end
    :ok
  end

  def finish(job_id) do
    channel = pg2_channel(job_id)
    Node.list
    |> Enum.map(fn(node) ->
      :rpc.call(node, GenServer, :call, [channel, :finish])
    end)
    |> Enum.filter(&( &1 ))
    |> List.first
  end

  # Server Callback
  def init(job_id) do
    channel = pg2_channel(job_id)
    :pg2.create(channel)
    :pg2.join(channel, self())
    {:ok, [job_id]}
  end

  def handle_call(:finish, from, state) do
    GenServer.reply(from, state)
    {:stop, :normal, state}
  end

  def handle_info({:update, event}, state) do
    :timer.sleep(500)
    {:noreply, [event | state]}
  end

  defp pg2_channel(job_id) when is_binary(job_id) do
    String.to_atom("job.pg2.#{job_id}")
  end
end
