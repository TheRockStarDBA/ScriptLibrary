SET NOCOUNT ON 
GO
DECLARE @ShowConstraintIndexes CHAR(1) = 'N', 
	@TableName VARCHAR(256) = 'dbo.<tablename>',
	@ReadFraction DECIMAL(3,3) = 0.001

IF @TableName = ''
BEGIN

;with baseData as (
SELECT SCHEMA_NAME(o.schema_id) as SchemaName, o.name as TableName, i.name as IndexName, p.index_id as idxID, 
	CASE WHEN i.is_primary_key = 1 then 'isPK' 
		WHEN i.is_primary_key <> 1 and i.is_unique_constraint = 1 then 'isUQconstr'
		WHEN i.is_primary_key <> 1 and i.is_unique_constraint <> 1 and i.is_unique = 1 then 'isUniq'
		else '' 
		END AS Cnstrts,
	u.user_seeks+u.user_scans+u.user_lookups as TotalReadActivity,
	SUM(u.user_seeks+u.user_scans+u.user_lookups) OVER (PARTITION BY p.object_id) as TableReadActivity,
	u.user_seeks, u.user_scans, u.user_lookups, u.user_updates, u.last_user_seek, u.last_user_scan, u.last_user_lookup, u.last_user_update, 
	p.reserved_page_count as page_count, i.fill_factor as FillF,p.row_count
from sys.dm_db_partition_stats p
	inner join sys.objects o
		on p.object_id = o.object_id
	inner join sys.indexes i
		on p.object_id = i.object_id
		and p.index_id = i.index_id
	left outer join sys.dm_db_index_usage_stats u
		on p.object_id = u.object_id
		and p.index_id = u.index_id
		and u.database_id = DB_ID()
WHERE 1=1
AND SCHEMA_NAME(o.schema_id) <> 'sys'
),
level2 as (
select CASE WHEN TableReadActivity = 0 THEN 'Table_NoActivity?'		--if the TABLE has no activity, we have a problem
			WHEN (user_seeks+user_scans) = 0 THEN 'Index Not Used'
			WHEN (user_seeks+user_scans) < 50 THEN 'Index Barely Used'
			WHEN user_seeks <= user_scans THEN 'Seeks <= Scans'				--indexes hopefully are supporting seeks more than scans
			WHEN ((user_seeks+user_scans)*1.)/TableReadActivity < @ReadFraction THEN 'Idx Reads < ' + convert(varchar(20),@ReadFraction*100) + '% of Table Reads'		--the index's use is pretty low compared to the total table activity
			WHEN (user_updates <> 0 and (user_seeks+user_scans)*1./user_updates < 0.75) THEN 'Idx Reads < 75% of index maint'
			ELSE '???'
			END as ScopeReason
	,
CASE WHEN TableReadActivity = 0 THEN 1		
			WHEN (user_seeks+user_scans) = 0 THEN 2
			WHEN (user_seeks+user_scans) < 50 THEN 3
			WHEN user_seeks <= user_scans THEN 4
			WHEN (user_updates <> 0 and (user_seeks+user_scans)*1./user_updates < 0.75) THEN 5
			WHEN ((user_seeks+user_scans)*1.)/TableReadActivity < @ReadFraction THEN 6
			ELSE 0	--???
			END as ScopePriority,
	SchemaName, TableName, IndexName, idxID, Cnstrts,  page_count*8/1024 as size_mb, 
	TableReadActivity, user_seeks, user_scans, user_lookups, user_updates, last_user_seek, last_user_scan, last_user_lookup, last_user_update, 
	FillF, row_count  , page_count*8 as size_kb
from baseData 
where 1=1
and idxID <> 0
and (
	(ISNULL(@ShowConstraintIndexes,'N') = 'N' AND LTRIM(RTRIM(Cnstrts)) = '')
		OR ISNULL(@ShowConstraintIndexes,'N') = 'Y'
	)
and (1 = (CASE WHEN TableReadActivity IS NULL THEN 0
			WHEN TableReadActivity = 0 THEN 1		--if the TABLE has no activity, we have a problem
			WHEN (user_seeks+user_scans) = 0 THEN 1
			WHEN (user_seeks+user_scans) < 50 THEN 1	--index barely used
			WHEN user_seeks <= user_scans THEN 1				--indexes hopefully are supporting seeks more than scans
			WHEN (user_seeks*1.)/TableReadActivity < @ReadFraction THEN 1		--the index's use is pretty low compared to the total table activity
			WHEN (user_updates <> 0 and (user_seeks+user_scans)*1./user_updates < 0.5) THEN 1
			ELSE 0
			END
			)	
	)
)
select ScopeReason, SchemaName+'.'+ TableName, IndexName, idxID, Cnstrts, size_mb, TableReadActivity, 
	user_seeks, user_scans, user_lookups, user_updates, 
	last_user_seek, last_user_scan, last_user_lookup, last_user_update, 
	FillF, row_count, size_kb 
from level2 
order by ScopePriority, (user_seeks + user_scans)
--order by SchemaName, TableName, IndexName 

END
ELSE
BEGIN
DECLARE @IndexKeys VARCHAR(4000)='', @IncludedColumns VARCHAR(4000)=''

IF OBJECT_ID('TempDB..#IndexAnalysis1') IS NOT NULL
	DROP TABLE #IndexAnalysis1

SELECT p.object_id,SCHEMA_NAME(o.schema_id)  + '.'+ o.name as TableName, i.name as IndexName, p.index_id as idxID, 
	CASE WHEN i.is_primary_key = 1 then 'isPK' 
		WHEN i.is_primary_key <> 1 and i.is_unique_constraint = 1 then 'isUQconstr'
		WHEN i.is_primary_key <> 1 and i.is_unique_constraint <> 1 and i.is_unique = 1 then 'isUniq'
		else '' 
		END AS Cnstrts,
	u.user_seeks, u.user_scans, u.user_lookups, u.user_updates, u.last_user_seek, u.last_user_scan, u.last_user_lookup, u.last_user_update, 
	p.reserved_page_count as page_count, i.fill_factor as FillF,p.row_count, 
	i.has_filter
INTO #IndexAnalysis1
from sys.dm_db_partition_stats p
	inner join sys.objects o
		on p.object_id = o.object_id
	inner join sys.indexes i
		on p.object_id = i.object_id
		and p.index_id = i.index_id
	left outer join sys.dm_db_index_usage_stats u
		on p.object_id = u.object_id
		and p.index_id = u.index_id
		and u.database_id = DB_ID()
WHERE 1=1
AND p.object_id = object_id(@TableName)

ALTER TABLE #IndexAnalysis1 ADD IndexKeys VARCHAR(4000), IncludedColumns VARCHAR(4000)

DECLARE @objid int, @indid int
DECLARE myCursor CURSOR FOR 
SELECT object_id, idxID
FROM #IndexAnalysis1

OPEN myCursor
FETCH myCursor INTO @objid, @indid

WHILE @@FETCH_STATUS = 0
BEGIN

	SELECT @IndexKeys = @IndexKeys + c.name + ','
	FROM sys.index_columns ic
		INNER JOIN sys.columns c
			ON c.object_id = ic.object_id
			AND c.column_id = ic.column_id
	WHERE ic.object_id = @objid
	AND ic.index_id = @indid
	AND ic.is_included_column <> 1
	ORDER BY ic.index_column_id

	SELECT @IncludedColumns = @IncludedColumns + c.name + ','
	FROM sys.index_columns ic
		INNER JOIN sys.columns c
			ON c.object_id = ic.object_id
			AND c.column_id = ic.column_id
	WHERE ic.object_id = @objid
	AND ic.index_id = @indid
	AND ic.is_included_column = 1
	ORDER BY ic.index_column_id


	UPDATE #IndexAnalysis1 
	SET IndexKeys = @IndexKeys, IncludedColumns = @IncludedColumns
	WHERE object_id = @objid 
	AND idxID = @indid
	
	SET @IndexKeys = ''
	SET @IncludedColumns = ''

	FETCH myCursor INTO @objid, @indid
END 

CLOSE myCursor
DEALLOCATE myCursor


select IndexName, Cnstrts, user_seeks as useeks, user_scans as uscans, user_lookups as ulkups, user_updates as uupd, 
	IndexKeys, IncludedColumns as InclCols, page_count*8/1024 as size_MB, page_count, has_filter as filt,
	FillF, row_count, last_user_seek, last_user_scan, last_user_lookup, last_user_update, idxID
from #IndexAnalysis1
END
