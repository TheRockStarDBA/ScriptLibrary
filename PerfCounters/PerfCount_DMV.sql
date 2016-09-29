/* I got this query via a Profiler trace. SQL Agent actually runs this query
against SQL Server in order to find the values for the counters from master.dbo.sysperfinfo
so that it can tell whether certain counters are over a threshold, and thus send
one of its SQL Agent alerts.

Some of the values for the counters are hard to believe (i.e., I've seen 100,000 logins per second),
but many of them look reasonable. 

This query comes in handy when you can't get to Perfmon, such as at Novant.

Obviously, you would want to modify this a bit for

sys.dm_os_performance_counters

*/

-- sp_sqlagent_get_perf_counters
SELECT 'object_name' = RTRIM(SUBSTRING(spi1.object_name, 1, 50)),
         'counter_name' = RTRIM(SUBSTRING(spi1.counter_name, 1, 50)),
         'instance_name' = CASE spi1.instance_name
                             WHEN N'' THEN NULL
                             ELSE RTRIM(spi1.instance_name)
                           END,
         'value' = CASE spi1.cntr_type
                     WHEN 537003008 -- A ratio
                       THEN CONVERT(FLOAT, spi1.cntr_value) / (SELECT CASE spi2.cntr_value WHEN 0 THEN 1 ELSE spi2.cntr_value END
                                                               FROM master.dbo.sysperfinfo spi2
                                                               WHERE (spi1.counter_name + ' ' = SUBSTRING(spi2.counter_name, 1, PATINDEX('% Base%', spi2.counter_name)))
                                                                 AND (spi1.instance_name = spi2.instance_name)
                                                                 AND (spi2.cntr_type = 1073939459))
                     ELSE spi1.cntr_value
                   END
  FROM master.dbo.sysperfinfo spi1
  WHERE (spi1.cntr_type <> 1073939459) -- Divisors

go
