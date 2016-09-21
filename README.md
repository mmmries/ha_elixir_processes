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
