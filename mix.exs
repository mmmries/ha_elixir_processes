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

  defp run_job([how_many_jobs]) do
    :pong = Node.ping(:"n1@mmmries-pro")
    :pong = Node.ping(:"n2@mmmries-pro")
    :pong = Node.ping(:"n3@mmmries-pro")

    how_many_jobs = String.to_integer(how_many_jobs)

    job_ids = Enum.map((1..how_many_jobs), &( "start#{&1}" ))
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
end
