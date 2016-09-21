defmodule Job do
  use GenServer

  def start(job_id) do
    node = Node.list |> Enum.shuffle |> List.first
    :rpc.call(node, GenServer, :start, [__MODULE__, job_id, [name: {:global, job_id}]])
  end

  def update(job_id, event) do
    GenServer.call({:global, job_id}, {:update, event})
  end

  def finish(job_id) do
    GenServer.call({:global, job_id}, :finish)
  end

  # Server Callback
  def init(job_id) do
    {:ok, [job_id]}
  end

  def handle_call({:update, event}, _from, state) do
    :timer.sleep(500)
    {:reply, :ok, [event | state]}
  end
  def handle_call(:finish, from, state) do
    GenServer.reply(from, state)
    {:stop, :normal, state}
  end
end
