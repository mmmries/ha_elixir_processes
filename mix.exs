defmodule AvailableProcesses.Mixfile do
  use Mix.Project

  def project do
    [app: :available_processes,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     aliases: aliases()]
  end

  def application do
    [applications: [:logger]]
  end

  defp aliases do
    [
      "run_job": ["compile", &run_job/1],
    ]
  end

  defp deps do
    []
  end

  # Run a set of jobs, update them and finish them
  defp run_job([how_many_jobs]) do
    connect_to_servers
    job_ids = how_many_to_job_ids(how_many_jobs)
    start_jobs(job_ids)
    IO.puts "started all the jobs, running updates now"
    :timer.sleep(5_000)
    send_update_messages(job_ids)
    finish_and_check(job_ids)
  end

  defp start_jobs(job_ids) do
    Enum.each(job_ids, &( {:ok, _pid} = Job.start(&1) ))
  end
  defp send_update_messages(job_ids) do
    Enum.each(job_ids, fn(job_id) ->
      update_msg = "#{job_id}.update"
      :ok = Job.update(job_id, update_msg)
    end)
  end
  defp finish_and_check(job_ids) do
    Enum.each(job_ids, fn(job_id) ->
      update_msg = "#{job_id}.update"
      [^update_msg, ^job_id] = Job.finish(job_id)
      IO.puts "checked #{job_id}"
    end)
  end

  # Helper function
  defp connect_to_servers do
    :pong = Node.ping(:"n1@localhost")
    :pong = Node.ping(:"n2@localhost")
    :pong = Node.ping(:"n3@localhost")
  end
  defp how_many_to_job_ids(how_many) do
    how_many = String.to_integer(how_many)
    Enum.map((1..how_many), &( "start#{&1}" ))
  end
end
