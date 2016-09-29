--TODO: we need to add in some sort of code for "outer apply sys.dm_exec_cached_plan_dependent_objects(cp.plan_handle) depobj"
-- and look at the depobj.cacheobjtype field (typically will be "Executable Plan")
-- Query Script #1: Pull a high-level view of the Plan Cache. We usually want higher use counts for our plans
select cacheobjtype, objtype, 
	[SingleUse] = SUM(CASE WHEN usecounts = 1 THEN 1 ELSE 0 END),
	[2through5Uses] = SUM(CASE WHEN usecounts > 1 and usecounts <= 5 THEN 1 ELSE 0 END),
	[6through10Uses] = SUM(CASE WHEN usecounts > 5 and usecounts <= 10 THEN 1 ELSE 0 END),
	[11through50Uses] = SUM(CASE WHEN usecounts > 10 and usecounts < 50 THEN 1 ELSE 0 END),
	[gt50Uses] = SUM(CASE WHEN usecounts > 50 THEN 1 ELSE 0 END),
	[#Plans] = COUNT(*),
	[TotalUseCounts] = SUM(convert(bigint,usecounts)),
	SUM(convert(bigint,size_in_bytes))/1024/1024 as Total_size_MB,
	AVG(convert(bigint,size_in_bytes))/1024/1024 as Avg_size_in_bytes
from sys.dm_exec_cached_plans 
group by cacheobjtype, objtype 
order by 8 desc 
--END SCRIPT

--Query Script #2: Pull info from plan cache into temp tables (helps the query optimizer in this case)
IF OBJECT_ID('tempdb..#SingleUsePlans') IS NOT NULL 
BEGIN
	drop table #SingleUsePlans
END
IF OBJECT_ID('tempdb..#SingleUseQueryText') IS NOT NULL 
BEGIN
	drop table #SingleUseQueryText
END 
CREATE TABLE #SingleUsePlans (plan_handle varbinary(64));
CREATE TABLE #SingleUseQueryText (plan_handle varbinary(64), sql_handle varbinary(64), total_worker_time bigint, 
		query_hash binary(8), query_plan_hash binary(8), querytext varchar(max))

--We're primarily after single-use ad-hoc plans
insert into #SingleUsePlans (plan_handle)
SELECT cp.plan_handle
FROM sys.dm_exec_cached_plans cp
where cp.usecounts = 1 
and cacheobjtype = 'Compiled Plan'
and objtype = 'Adhoc'

insert into #SingleUseQueryText (plan_handle, sql_handle, total_worker_time,
		query_hash, query_plan_hash, querytext)
select cp.plan_handle, qs.sql_handle, qs.total_worker_time, 
	qs.query_hash, qs.query_plan_hash, null 
from #SingleUsePlans cp
	inner join sys.dm_exec_query_stats qs
		on cp.plan_handle = qs.plan_handle

update targ 
set querytext = txt.text
from #SingleUseQueryText targ 
	cross apply sys.dm_exec_sql_text (targ.sql_handle) txt
--END SCRIPT


--Query Script #3: Are certain query_hash values much more common? 
--		and how many different query plans is a given query_hash value likely to have?
select distinct t.query_hash, t.query_plan_hash, 
	COUNT(*) OVER (partition by query_hash) as QueryHashCount, 
	COUNT(*) OVER (partition by query_hash, query_plan_hash) as BothCount
from #SingleUseQueryText t
order by 3 desc 
--END SCRIPT

--Query Script #4: For a common query_hash value, what is the T-SQL?
select t.plan_handle, t.query_hash, querytext 
from #SingleUseQueryText t
where t.query_hash = <query_hash value>
--END SCRIPT
