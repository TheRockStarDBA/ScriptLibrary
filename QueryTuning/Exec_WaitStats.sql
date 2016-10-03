USE <dbname>
GO
IF OBJECT_ID('tempdb..#wsquerydelta') IS NOT NULL
BEGIN
	DROP TABLE #wsquerydelta
END	
GO
SELECT 'Before' as Label1, SYSDATETIME() as CaptureTime, * 
INTO #wsquerydelta
FROM sys.dm_os_wait_stats ws
GO




--<insert query here>


INSERT INTO #wsquerydelta 
(Label1, CaptureTime, wait_type, waiting_tasks_count, wait_time_ms, max_wait_time_ms, signal_wait_time_ms)
SELECT 'After', SYSDATETIME(), wait_type, waiting_tasks_count, wait_time_ms, max_wait_time_ms, signal_wait_time_ms
FROM sys.dm_os_wait_stats ws
GO

;WITH base as (
SELECT a.wait_type, 
	waiting_tasks_count = CASE WHEN b.waiting_tasks_count IS NULL THEN a.waiting_tasks_count ELSE (a.waiting_tasks_count - b.waiting_tasks_count) END, 
	wait_time_ms = CASE WHEN b.wait_time_ms IS NULL THEN a.wait_time_ms ELSE (a.wait_time_ms - b.wait_time_ms) END, 
	signal_wait_time_ms = CASE WHEN b.signal_wait_time_ms IS NULL THEN a.signal_wait_time_ms ELSE (a.signal_wait_time_ms - b.signal_wait_time_ms) END,
	max_wait_time_ms = CASE WHEN b.max_wait_time_ms IS NULL THEN a.max_wait_time_ms 
							ELSE (CASE WHEN b.max_wait_time_ms > a.max_wait_time_ms THEN b.max_wait_time_ms ELSE a.max_wait_time_ms END)
						END
FROM #wsquerydelta a
	LEFT OUTER JOIN #wsquerydelta b
		ON a.wait_type = b.wait_type
WHERE a.Label1 = 'After'
AND b.Label1 = 'Before'
)
SELECT *
FROM base 
WHERE waiting_tasks_count > 0 
OR wait_time_ms > 0 
OR signal_wait_time_ms > 0
;
