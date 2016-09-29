--My script (not sure about Slava's) may have issues for very-short-lived blocking. More troubleshooting/research is needed here.

declare @blockingchain table (session_id int, ec int, blocking_id int, blocking_ec int, wait_type varchar(100), resource_description varchar(255))


/* My script was built after viewing this blog post by Slava: http://blogs.msdn.com/b/slavao/archive/2006/11/14/sqlosdmv-s-continue.aspx
--Here's his take on a task chain.
WITH TaskChain (waiting_task_address, blocking_task_address, ChainId, Level)
AS
(-- Anchor member definition: use self join so that we output only tasks that blocking others and remove dupliates
 SELECT DISTINCT A.waiting_task_address, A.blocking_task_address, A.waiting_task_address As ChainId, 0 AS Level
 FROM sys.dm_os_waiting_tasks as A
	JOIN sys.dm_os_waiting_tasks as B
		ON A.waiting_task_address = B.blocking_task_address
 WHERE A.blocking_task_address IS NULL
	UNION ALL
-- Recursive member definition: Get to the next level waiting tasks
 SELECT A.waiting_task_address, A.blocking_task_address, B.ChainId, Level + 1
 FROM sys.dm_os_waiting_tasks AS A
	JOIN TaskChain AS B 
		ON B.waiting_task_address = A.blocking_task_address
)
select waiting_task_address, blocking_task_address, ChainId, Level  
from TaskChain
order by ChainId 
*/


INSERT INTO @blockingchain 
SELECT case when session_id is null 
		then convert(int, waiting_task_address) 
		else session_id end as session_id, 
	isnull(exec_context_id,-1) as ec, 
		case when blocking_session_id is null
		then convert(int, blocking_task_address)
		else blocking_session_id end as blocking_session_id, 

	case when blocking_session_id > 50 and blocking_exec_context_id is null 
		then 0 
		else -1 end as blocking_ec, 
	wait_type, resource_description 
from sys.dm_os_waiting_tasks
WHERE wait_type not in ('XE_DISPATCHER_WAIT','ONDEMAND_TASK_QUEUE','FILESTREAM_WORKITEM_QUEUE','DISPATCHER_QUEUE_SEMAPHORE',
		'CHECKPOINT_QUEUE','REQUEST_FOR_DEADLOCK_SEARCH','FT_IFTS_SCHEDULER_IDLE_WAIT','BROKER_TO_FLUSH','BROKER_TRANSMITTER',
		'SLEEP_TASK','LAZYWRITER_SLEEP','SP_SERVER_DIAGNOSTICS_SLEEP','XE_TIMER_EVENT','KSOURCE_WAKEUP','BROKER_EVENTHANDLER',
		'FT_IFTSHC_MUTEX','LOGMGR_QUEUE','DIRTY_PAGE_POLL','CLR_AUTO_EVENT','SQLTRACE_INCREMENTAL_FLUSH_SLEEP','HADR_FILESTREAM_IOMGR_IOCOMPLETION')

;WITH blockingchainCTE (session_id, ec, blocking_id, blocking_ec, chain_id, wait_type, resource_description, chainorder) as
(SELECT base.blocking_id, base.blocking_ec, NULL, NULL, base.blocking_id, CONVERT(varchar(100),NULL), CONVERT(varchar(255),NULL), 0
FROM @blockingchain base
WHERE NOT EXISTS (SELECT * FROM @blockingchain base2
				WHERE base2.session_id = base.blocking_id
				AND base2.ec = base.blocking_ec)
UNION ALL
	SELECT t.session_id, t.ec, t.blocking_id, t.blocking_ec, r.chain_id, t.wait_type, t.resource_description ,r.chainorder + 1
	FROM @blockingchain t
		INNER JOIN blockingchainCTE r
			ON t.blocking_id = r.session_id
			AND t.blocking_ec = r.ec
)
SELECT c.chain_id,c.session_id as snap_spid,
	c.ec as snap_ec, 
	c.blocking_id as snap_blk_spid, c.blocking_ec as snap_blk_ec, c.chainorder,
	c.wait_type as snap_wait_type, c.resource_description as snap_resource_desc

	,'CURRENTDATA:', rq.wait_time as wait_time, rq.wait_type as wait_type, rq.wait_resource as wait_resource, 
	txt.text as BatchText,
	SUBSTRING(txt.text, (rq.statement_start_offset/2)+1, 
        ((CASE rq.statement_end_offset
          WHEN -1 THEN DATALENGTH(txt.text)
         ELSE rq.statement_end_offset
         END - rq.statement_start_offset)/2) + 1) AS statement_text,
	rq.last_wait_type, rq.start_time, rq.status, rq.command, rq.database_id, rq.user_id, rq.open_transaction_count as open_tran_cnt, 
	 rq.open_resultset_count as open_rs_cnt, rq.percent_complete, rq.cpu_time, rq.total_elapsed_time, rq.transaction_isolation_level as tranIsoLevel, 
	 rq.deadlock_priority, rq.granted_query_memory
	 --,qp.query_plan

FROM blockingchainCTE c

LEFT OUTER JOIN sys.dm_exec_requests rq 
	ON c.session_id = rq.session_id
OUTER APPLY sys.dm_exec_sql_text(rq.sql_handle) txt
--OUTER APPLY sys.dm_exec_query_plan(rq.plan_handle) qp

order by chain_id, chainorder, blocking_id, blocking_ec, snap_spid 

--dbcc inputbuffer(52)
