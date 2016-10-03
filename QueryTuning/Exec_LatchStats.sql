--USE <dbname>
GO
IF OBJECT_ID('tempdb..#lsquerydelta') IS NOT NULL
BEGIN
	DROP TABLE #lsquerydelta
END	
GO

SELECT 'Before' as Label1, SYSDATETIME() as CaptureTime, * 
INTO #lsquerydelta
FROM sys.dm_os_latch_stats ws
GO

--<insert query here>

INSERT INTO #lsquerydelta 
(Label1, CaptureTime, latch_class, waiting_requests_count, wait_time_ms, max_wait_time_ms)
SELECT 'After', SYSDATETIME(), latch_class, waiting_requests_count, wait_time_ms, max_wait_time_ms
FROM sys.dm_os_latch_stats ws
GO

;WITH base as (
SELECT a.latch_class, 
	waiting_requests_count = CASE WHEN b.waiting_requests_count IS NULL THEN a.waiting_requests_count ELSE (a.waiting_requests_count - b.waiting_requests_count) END, 
	wait_time_ms = CASE WHEN b.wait_time_ms IS NULL THEN a.wait_time_ms ELSE (a.wait_time_ms - b.wait_time_ms) END,
	max_wait_time_ms = CASE WHEN b.max_wait_time_ms IS NULL THEN a.max_wait_time_ms 
							ELSE (CASE WHEN b.max_wait_time_ms > a.max_wait_time_ms THEN b.max_wait_time_ms ELSE a.max_wait_time_ms END)
						END
FROM #lsquerydelta a
	LEFT OUTER JOIN #lsquerydelta b
		ON a.latch_class = b.latch_class
WHERE a.Label1 = 'After'
AND b.Label1 = 'Before'
)
SELECT *
FROM base 
WHERE waiting_requests_count > 0 
OR wait_time_ms > 0 
;
