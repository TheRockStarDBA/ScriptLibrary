select
gs.group_handle,gs.unique_compiles,gs.user_seeks,gs.last_user_seek,gs.avg_total_user_cost,gs.avg_user_impact,
d.database_id,d.object_id,d.statement,d.equality_columns,d.inequality_columns,d.included_columns
from sys.dm_db_missing_index_group_stats gs
inner join sys.dm_db_missing_index_groups g
on gs.group_handle = g.index_group_handle
inner join sys.dm_db_missing_index_details d
on g.index_handle = d.index_handle
where gs.user_seeks > 100
order by gs.user_seeks desc

