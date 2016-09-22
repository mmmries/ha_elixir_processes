# The Use Case

I started thinking about this topic because of a problem I had at work.
The simplified version of this problem is that I needed to kick of some background work.
The work involved lots of network IO and usually took 1-3min for each "job".
The results of the job usually remained available for ~10min so another system could collect them.

I wanted to do all the processing and holding of this data in-memory to avoid bottlenecks and scaling issues with separate persistence stores like redis or postgres.
I also wanted to be able to release new versions of the software without worrying about destroying existing jobs.
It would also be nice if the jobs and results could survive the unexpected death of one of the servers.

# The Test Case

The simplistc test case would be to use the `Job` module as a simplistic GenServer.
To run this example start three server nodes like this (each in a different terminal):

```
$ iex --sname n1@localhost --cookie test -S mix
$ iex --sname n2@localhost --cookie test -S mix
$ iex --sname n3@localhost --cookie test -S mix
```

Then run the test script by running:

`$ elixir --sname c1@localhost --cookie test -S mix run_job 10`

This will start 10 jobs, send updates to all 10 then finish all 10 and check for success along the way.

# OTP Example

The `Job.Otp` implementation let's each work try to restart itself somewhere else on the cluster when receiving the `shutdown` message (ie graceful shtudown).

```
$ iex --name n1@127.0.0.1 --erl '-config sys.config' -S mix 
$ iex --name n2@127.0.0.1 --erl '-config sys.config' -S mix 
```

> Note: I don't know why gproc requires you do use the sys.config / joining a cluster at boot rather than at runtime.
> Additional new nodes attempting to join at runtime will work even if they aren't listed in the sys.config values.
> But if you start a node without trying to join the cluster at boot it won't share any gproc registrations ¯\_(ツ)\_/¯

Now on each node you can start jobs like `Job.Otp.start("ohai")` and see call the process by running `Job.Otp.check_results("ohai")` on either node.
You can also gracefully shut down one of the nodes by running something like `:init.stop` or `Application.stop(:available_processes)`.
All of the jobs on that node will try to re-spawn themselves somewhere else on the cluster before they get shut down.
