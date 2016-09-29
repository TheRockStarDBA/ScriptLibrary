/*  By File Group */
SELECT FileGroupName, SchemaName, TableName, IndexName, index_id, Rsvd_MB
from (SELECT dsp.name as FileGroupName,  SCHEMA_NAME(o.schema_id) as SchemaName,
 o.name as TableName,  i.name as IndexName, 
 i.index_id, (ps.reserved_page_count*8/1024) as Rsvd_MB
FROM sys.objects o
 INNER JOIN sys.indexes i  ON o.object_id = i.object_id
 INNER JOIN sys.data_spaces dsp  ON i.data_space_id = dsp.data_space_id
 INNER JOIN sys.dm_db_partition_stats ps  ON i.object_id = ps.object_id
  AND i.index_id = ps.index_id
WHERE o.type = 'U'  and (ps.reserved_page_count*8/1024) > 400 --only indexes > 400 MB
) ss
WHERE 1=1
--AND ss.tablename in ()
ORDER BY Rsvd_MB DESC 

