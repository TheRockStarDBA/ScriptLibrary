WITH VAS_Summary
AS ( SELECT VAS_Dump.RegionSize,
		Reserved = SUM(CASE ( CONVERT(INT, VAS_Dump.Base) ^ 0 )
			WHEN 0 THEN 0
				ELSE 1
			END),
		Free = SUM(CASE ( CONVERT(INT, VAS_Dump.Base) ^ 0 )
			WHEN 0 THEN 1
				ELSE 0
			END)
	FROM 
		( 
			SELECT SUM(region_size_in_bytes) [RegionSize],
				region_allocation_base_address [Base]
			FROM   sys.dm_os_virtual_address_dump
			WHERE  region_allocation_base_address <> 0x0
			GROUP  BY region_allocation_base_address
		UNION
			SELECT region_size_in_bytes [RegionSize],
				region_allocation_base_address [Base]
			FROM   sys.dm_os_virtual_address_dump
			WHERE  region_allocation_base_address = 0x0
		) AS VAS_Dump
	GROUP BY RegionSize
)
SELECT SS.Tot_avail_mem_kb, SS.Tot_Reserved_Mem_KB, SS2.Max_free_size_KB
FROM (
	SELECT SUM(CONVERT(BIGINT, RegionSize) * Free) / 1024 AS [Tot_avail_mem_KB],
	SUM(CONVERT(BIGINT, RegionSize) * Reserved) / 1024 as [Tot_Reserved_Mem_KB]
	FROM VAS_Summary a
) SS
	CROSS JOIN (SELECT CAST(MAX(RegionSize) AS BIGINT) / 1024 AS [Max_free_size_KB] 
				FROM VAS_Summary b WHERE Free <> 0) SS2

				
/* I got this query from Slava Oks blog.

It basically returns all free areas and their size (the size is in hex).

You can use this to determine
	1. the biggest free region
		and thus determine whether there is Virtual Address fragmentation due to no large chunks

	2. the sum of all free regions
		and thus determine whether there is VAS fragmentation due to little space left

*/

select Size = CONVERT(bigint,VaDump.Size), Reserved = sum(case (convert (INT,VaDump.Base) ^ 0) when 0 then 0 else 1 end), 
Free = sum(case (convert (INT,VaDump.Base) ^ 0x0) when 0 then 1 else 0 end) 
from
(
--- combine all allocation according with allocation base, don't take into account allocations with zero region_allocation_base_address 
select CONVERT (varbinary,sum(region_size_in_bytes)) AS Size, 
region_allocation_base_address 
AS Base 
from sys.dm_os_virtual_address_dump 
where region_allocation_base_address <> 0x0 
group by region_allocation_base_address 
UNION 
( 
--- we shouldn't be grouping allocations with zero allocation base 
--- just get them as is 
select CONVERT (varbinary,region_size_in_bytes), region_allocation_base_address 
from sys.dm_os_virtual_address_dump 
where region_allocation_base_address = 0x0) 
)
as
VaDump 
group by Size 
Order by Reserved desc

