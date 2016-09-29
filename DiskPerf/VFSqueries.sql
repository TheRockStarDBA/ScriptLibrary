/* 
Very useful stuff

The first 2 queries are from
http://www.sqlservercentral.com/blogs/pearlknows/archive/2009/8/18/i-o-i-o-it-s-why-my-server-s-slow-examing-i-o-statistics.aspx

The 3rd query is from Itzik Ben-Gan's T-SQL Querying (2005) book, page 82

*/


/*
Calculating the Percentage of I/O for Each Database
--------------------------------------------------- */
WITH Agg_IO_Stats
AS
(
  SELECT
    DB_NAME(database_id) AS database_name,
    CAST(SUM(num_of_bytes_read + num_of_bytes_written) / 1048576.
         AS DECIMAL(12, 2)) AS io_in_mb
  FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS DM_IO_Stats
  GROUP BY database_id
)
SELECT
  ROW_NUMBER() OVER(ORDER BY io_in_mb DESC) AS row_num,
  database_name,
  io_in_mb,
  CAST(io_in_mb / SUM(io_in_mb) OVER() * 100
       AS DECIMAL(5, 2)) AS pct
FROM Agg_IO_Stats
ORDER BY row_num;



/* ----------------------------------------------------
Calculating the percentage of I/O by Drive
---------------------------------------------------- */
With g as
(select db_name(mf.database_id) as database_name, mf.physical_name, 
left(mf.physical_name, 1) as drive_letter, 
vfs.num_of_writes, 
vfs.num_of_bytes_written as BYTESWRITTEN, 
vfs.io_stall_write_ms, 
mf.type_desc, vfs.num_of_reads, vfs.num_of_bytes_read, vfs.io_stall_read_ms,
vfs.io_stall, vfs.size_on_disk_bytes
from sys.master_files mf
join sys.dm_io_virtual_file_stats(NULL, NULL) vfs
on mf.database_id=vfs.database_id and mf.file_id=vfs.file_id
--order by vfs.num_of_bytes_written desc)
)
select database_name,drive_letter, BYTESWRITTEN,
Percentage = RTRIM(CONVERT(DECIMAL(5,2),
BYTESWRITTEN*100.0/(SELECT SUM(BYTESWRITTEN) FROM g))) --where drive_letter='R')))
+ '%'
from g --where drive_letter='R'
order by BYTESWRITTEN desc

/*------------------------------------------------------- */


/* Calculating the IO Stall percentage for each data and log file */
WITH DBIO AS
(
  SELECT
    DB_NAME(IVFS.database_id) as db,
	CASE WHEN MF.type = 1 THEN 'log' ELSE 'data' END AS file_type,
	SUM(IVFS.num_of_bytes_read + IVFS.num_of_bytes_written) AS io,
	SUM(IVFS.io_stall) AS io_stall
  FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS IVFS
	JOIN sys.master_files AS MF
		ON IVFS.database_id = MF.database_id
		AND IVFS.file_id = MF.file_id
	GROUP BY DB_NAME(IVFS.database_id), MF.type
  )
SELECT db, file_type,
	CAST(1. * io / (1024 * 1024) AS DECIMAL(12,2)) AS io_mb,
	CAST(io_stall / 1000. AS DECIMAL(12,2)) AS io_stall_s,
	CAST(100. * io_stall / SUM(io_stall) OVER()
		AS DECIMAL(10,2)) AS io_stall_pct,
	ROW_NUMBER() OVER(ORDER BY io_stall DESC) AS rn
  FROM DBIO
  ORDER BY io_stall DESC;


--this basic one is mine
select dbname, numReads, convert(decimal(15,1),numBytesRead/1024./1024./1024.) as numGBread, 
	convert(decimal(15,1),ioReadStall_ms/1000./3600.) as ioReadStall_hr, 
	numWrites, convert(decimal(15,1),numBytesWritten/1024./1024./1024.) as numGBwritten, 
	convert(decimal(15,1),ioWriteStall_ms/1000./3600.) as ioWriteStall_sec,
		convert(decimal(15,1),(numBytesRead + numBytesWritten)/1024./1024./1024.) as numGBtotal
from (
select dbname, sum(num_of_reads) as numReads, sum(num_of_bytes_read) as numBytesRead, sum(io_stall_read_ms) as ioReadStall_ms, 
	sum(num_of_writes) as numWrites, sum(num_of_bytes_written) as numBytesWritten, sum(io_stall_write_ms) as ioWriteStall_ms
from 
(select db_name(database_id) dbname, num_of_reads, num_of_bytes_read, io_stall_read_ms, 
	num_of_writes, num_of_bytes_written, io_stall_write_ms 
from sys.dm_io_virtual_file_stats(null, null) 
where 1=1
--and database_id = 2 
) ss
group by dbname 
) ss2
order by (numBytesRead + numBytesWritten) desc 
