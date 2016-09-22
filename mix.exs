defmodule AvailableProcesses.Mixfile do
  use Mix.Project

  def project do
    [app: :available_processes,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: true,
     deps: deps(),
     aliases: aliases()]
  end

  def application do
    [
      applications: [:logger, :gproc],
      mod: {AvailableProcesses, []},
    ]
  end

  defp aliases do
    [
      "run_job": ["compile", &run_job/1],
      "run_pg2": ["compile", &run_pg2/1],
    ]
  end

  defp deps do
    [
      {:gen_leader, "~> 0.1.0"},
      {:gproc, "~> 0.6.1"},
    ]
  end

  # Run a set of jobs, update them and finish them
  defp run_job([how_many_jobs]) do
    run_experiment(Job, how_many_jobs)
  end

  defp run_pg2([how_many_jobs]) do
    run_experiment(Job.Pg2, how_many_jobs)
  end

  # Helper function
  defp run_experiment(job_module, how_many_jobs) do
    connect_to_servers
    job_ids = how_many_to_job_ids(how_many_jobs)
    start_jobs(job_module, job_ids)
    IO.puts "started all the jobs, running updates now"
    send_update_messages(job_module, job_ids)
    :timer.sleep(100)
    finish_and_check(job_module, job_ids)
  end
  defp connect_to_servers do
    :pong = Node.ping(:"n1@localhost")
    :pong = Node.ping(:"n2@localhost")
    :pong = Node.ping(:"n3@localhost")
  end
  defp how_many_to_job_ids(how_many) do
    how_many = String.to_integer(how_many)
    Enum.map((1..how_many), &( "start#{&1}" ))
  end
  defp start_jobs(job_module, job_ids) do
    Enum.each(job_ids, &( {:ok, _pid} = apply(job_module, :start, [&1]) ))
  end
  defp send_update_messages(job_module, job_ids) do
    Enum.each(job_ids, fn(job_id) ->
      update_msg = "#{job_id}.update"
      :ok = apply(job_module, :update, [job_id, update_msg])
    end)
  end
  defp finish_and_check(job_module, job_ids) do
    Enum.each(job_ids, fn(job_id) ->
      update_msg = "#{job_id}.update"
      case apply(job_module, :finish, [job_id]) do
        [^update_msg, ^job_id] -> :success!
        _ -> IO.puts "job #{job_id} had the wrong state"
      end
    end)
  end
end
