--select * from sys.dm_exec_cached_plans
select cacheobjtype, objtype, SubTotal, size_in_bytes/1024 as SubTotal_Size_KB, single_use, [2to5], [6to10], [11to50], [51to200], [gt200], 
	SUM(SubTotal) OVER () as TotalNumPlans
from (
select cacheobjtype, objtype, SUM(convert(bigint,size_in_bytes)) as size_in_bytes,
	SUM(convert(bigint,single_use)) as single_use,
	SUM(convert(bigint,[2to5])) as [2to5],
	SUM(convert(bigint,[6to10])) as [6to10],
	SUM(convert(bigint,[11to50])) as [11to50],
	SUM(convert(bigint,[51to200])) as [51to200],
	SUM(convert(bigint,[gt200])) as [gt200], 
	SUM(convert(bigint,single_use + [2to5] + [6to10] + [11to50] + [51to200] + [gt200])) as SubTotal
from 
(select cacheobjtype, objtype, size_in_bytes,
	case when usecounts = 1 then 1 else 0 end as single_use,
	case when usecounts between 2 and 5 then 1 else 0 end as [2to5],
	case when usecounts between 6 and 10 then 1 else 0 end as [6to10],
	case when usecounts between 11 and 50 then 1 else 0 end as [11to50],
	case when usecounts between 51 and 200 then 1 else 0 end as [51to200],
	case when usecounts > 200 then 1 else 0 end as [gt200]
from sys.dm_exec_cached_plans cp
) ss
group by cacheobjtype, objtype
) ss2
Order by SubTotal desc
