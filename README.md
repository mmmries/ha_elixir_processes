# The Use Case

I started thinking about this topic because of a problem I had at work.
The simplified version of this problem is that I needed to kick of some background work.
The work involved lots of network IO and usually took 1-3min for each "job".
The results of the job usually remained available for ~10min so another system could collect them.

I wanted to do all the processing and holding of this data in-memory to avoid bottlenecks and scaling issues with separate persistence stores like redis or postgres.
I also wanted to be able to release new versions of the software without worrying about destroying existing jobs.
It would also be nice if the jobs and results could survive the unexpected death of one of the servers.
