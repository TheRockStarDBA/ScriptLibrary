--replace token first
use @@dbass@@
go
select object_name(object_id), index_id, ss.allocation_unit_id, num_pages
from (
select allocation_unit_id, count(*) as num_pages
from sys.dm_os_buffer_descriptors bd
where database_id = db_id('@@dbass@@')
group by allocation_unit_id
having count(*) > 1000) ss
inner join sys.allocation_units au
on ss.allocation_unit_id = au.allocation_unit_id
inner join sys.partitions pt
on au.container_id = pt.partition_id
order by num_pages desc


select DBName, [#8kb_pages], MemUsage_MB, 
	SUM(MemUsage_MB) OVER () as TotalBufferPoolSize_mb
from 
(select db_name(database_id) as DBName, num_pages as [#8kb_pages], 
	convert(decimal(15,1),convert(bigint,num_pages)*8192./1024./1024.) as MemUsage_MB
from (
select database_id, count(*) as num_pages
from sys.dm_os_buffer_descriptors
group by database_id
) ss
) ss2
order by 2 desc
