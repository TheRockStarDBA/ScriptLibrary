--USE <dbname>
GO
IF OBJECT_ID('tempdb..#idxusgstats') IS NOT NULL
BEGIN
	DROP TABLE #idxusgstats
END	
GO
select * from sys.dm_db_index_usage_stats

SELECT 'Before' as Label1, SYSDATETIME() as CaptureTime, * 
INTO #idxusgstats
FROM sys.dm_db_index_usage_stats usg
GO

--<insert query here>

INSERT INTO #idxusgstats 
(Label1, CaptureTime, database_id, object_id, index_id, 
	user_seeks, user_scans, user_lookups, user_updates, 
	last_user_seek, last_user_scan, last_user_lookup, last_user_update,
	system_seeks, system_scans, system_lookups, system_updates, 
	last_system_seek, last_system_scan, last_system_lookup, last_system_update)
SELECT 'After', SYSDATETIME(), database_id, object_id, index_id, 
	user_seeks, user_scans, user_lookups, user_updates, 
	last_user_seek, last_user_scan, last_user_lookup, last_user_update,
	system_seeks, system_scans, system_lookups, system_updates, 
	last_system_seek, last_system_scan, last_system_lookup, last_system_update
FROM sys.dm_db_index_usage_stats usg
GO

;WITH base as (
SELECT DBName = DB_NAME(a.database_id), 
	ObjectName = OBJECT_NAME(a.object_id, a.database_id),
	a.index_id,

	user_seeks = CASE WHEN b.user_seeks IS NULL THEN a.user_seeks ELSE (a.user_seeks - b.user_seeks) END, 
	user_scans = CASE WHEN b.user_scans IS NULL THEN a.user_scans ELSE (a.user_scans - b.user_scans) END, 
	user_lookups = CASE WHEN b.user_lookups IS NULL THEN a.user_lookups ELSE (a.user_lookups - b.user_lookups) END, 
	user_updates = CASE WHEN b.user_updates IS NULL THEN a.user_updates ELSE (a.user_updates - b.user_updates) END, 

	a.last_user_seek, a.last_user_scan, a.last_user_lookup, a.last_user_update,

	system_seeks = CASE WHEN b.system_seeks IS NULL THEN a.system_seeks ELSE (a.system_seeks - b.system_seeks) END, 
	system_scans = CASE WHEN b.system_scans IS NULL THEN a.system_scans ELSE (a.system_scans - b.system_scans) END, 
	system_lookups = CASE WHEN b.system_lookups IS NULL THEN a.system_lookups ELSE (a.system_lookups - b.system_lookups) END, 
	system_updates = CASE WHEN b.system_updates IS NULL THEN a.system_updates ELSE (a.system_updates - b.system_updates) END, 

	a.last_system_seek, a.last_system_scan, a.last_system_lookup, a.last_system_update
FROM #idxusgstats a
	LEFT OUTER JOIN #idxusgstats b
		ON a.database_id = b.database_id
		AND a.object_id = b.object_id
		AND a.index_id = b.index_id
WHERE a.Label1 = 'After'
AND b.Label1 = 'Before'
)
SELECT *
FROM base 
WHERE (user_seeks > 0 
or user_scans > 0
or user_lookups > 0
or user_updates > 0
or system_seeks > 0
or system_scans > 0
or system_lookups > 0
or system_updates > 0

)
;
