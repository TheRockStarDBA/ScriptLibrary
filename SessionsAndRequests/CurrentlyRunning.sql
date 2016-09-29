--A script I wrote against the request-related DMVs before I had discovered sp_WhoIsActive. Still useful if
-- I'm in an environment where sp_WhoIsActive or other DMV aggregators aren't available.

BEGIN TRY 

SELECT rq.session_id as spid, 
CASE WHEN rq.command IN ('SELECT','UPDATE','DELETE','INSERT','WAITFOR','MERGE') THEN ''
	ELSE rq.command END as c,
	CONVERT(decimal(15,1),datediff(MILLISECOND, rq.start_time, getdate())/1000.) as dur_s,
	DB_Name(rq.database_id) as DBN,
	OBJECT_NAME(txt.objectid,txt.dbid) as oName,

	CASE WHEN rq.statement_start_offset = 0 THEN 
			CASE WHEN rq.statement_end_offset = 0 AND DATALENGTH(txt.text) < 2000 
					THEN txt.text 
				WHEN rq.statement_end_offset = 0 AND DATALENGTH(txt.text) >= 2000 
					THEN SUBSTRING(txt.text, 1, 2000)
				WHEN rq.statement_end_offset = -1
					THEN txt.text 
				ELSE SUBSTRING(txt.text, 1, rq.statement_end_offset/2 + 1) 
			END 
		ELSE SUBSTRING(txt.text, (rq.statement_start_offset/2)+1, 
        ((CASE rq.statement_end_offset
          WHEN -1 THEN DATALENGTH(txt.text)
         ELSE rq.statement_end_offset
         END - rq.statement_start_offset)/2) + 1) 
         END AS StmtText,

	CASE WHEN rq.wait_type IS NOT NULL AND rq.wait_type <> 'CXPACKET' AND rq.status <> 'suspended' THEN se.status
		WHEN wait_type IS NULL AND se.status <> 'running' THEN rq.status 
		ELSE '' END as s, 
	se.status,
	--blocking info
	rq.blocking_session_id as blk, convert(decimal(14,2),rq.wait_time/1000.) as wtSec, 
	CASE WHEN isnull(rq.wait_type, '<null>') <> isnull(rq.last_wait_type,'<null>')
		THEN rq.wait_type + ' (last: ' + rq.last_wait_type + ')'
		ELSE rq.wait_type END as wtTyp, 
	rq.wait_resource as wtRes, 

	--resource utilization
	convert(decimal(14,2),rq.cpu_time/1000.) as cpuT, 
	case when rq.granted_query_memory = 0 then CONVERT(decimal(14,1), -1)
		else convert(decimal(14,1),rq.granted_query_memory*8192./1024./1024.) end as qryMemMB,
	rq.logical_reads as LRds, rq.reads as PRds, rq.writes as Wr,  

	--resource history
	se.cpu_time as tCpuTm, 
	convert(decimal(14,2),se.total_scheduled_time/1000.) as tSchedTm, 
	convert(decimal(14,2),se.total_elapsed_time/1000.) as tElapTm,
	se.reads as totPRds, se.logical_reads as totLRds,se.writes as totWr, 
	se.memory_usage, --is this memory_usage field even worth including?

	--transaction info
	rq.open_transaction_count as OpenTrnCnt, rq.open_resultset_count as OpenRScnt, rq.transaction_id as TranID, 
	rq.transaction_isolation_level as IsoLvl,
	rq.lock_timeout as LckTmOt, rq.deadlock_priority as DLckPri,
	se.transaction_isolation_level as SessIso, se.lock_timeout as SessLckTmOt, se.deadlock_priority as SessDLckPri,

	--SQLOS
	rq.scheduler_id as Sched, rq.group_id as RGgrp, cn.node_affinity,

	--Activity History
	se.last_request_start_time, last_request_end_time, cn.last_read, cn.last_write,
	cn.num_reads, cn.num_writes, cn.most_recent_sql_handle,

	--Connection/Session Basic Info
	cn.connect_time, cn.client_net_address, cn.client_tcp_port, 
		--se.database_id as SessDBID only in SQL2012,
		--se.open_transaction_count as SessOpenTranCnt only in SQL2012, 

	--Connection Detailed Info
	 cn.local_net_address, cn.local_tcp_port, cn.net_transport, cn.protocol_type,
	  cn.endpoint_id as CnEndPntId, se.endpoint_id as sessEndPntId, 
	cn.net_packet_size, 
	se.host_name,se.host_process_id, se.program_name,  se.client_version, se.client_interface_name,
	 cn.most_recent_session_id, 
	 cn.connection_id, cn.parent_connection_id, 
	  
	--security info
	se.login_time, se.security_id, se.login_name, se.original_login_name, cn.encrypt_option, cn.auth_scheme,
	--se.authenticating_database_id only in SQL2012, 
	rq.user_id as DBUserID,

	--misc
	rq.percent_complete, rq.row_count as RowCnt, rq.nest_level, 
	se.row_count as SessRowCnt, rq.executing_managed_code, rq.start_time,

 	1
 	--,qp.query_plan
	--rq.task_address, 
FROM sys.dm_exec_requests rq
	inner join sys.dm_exec_sessions se 
		on rq.session_id = se.session_id
	inner join sys.dm_exec_connections cn
		on rq.connection_id = cn.connection_id
	outer apply sys.dm_exec_sql_text(rq.sql_handle) txt
	--outer apply sys.dm_exec_query_plan(rq.plan_handle) qp
WHERE 1=1
	--we want only user processes or background processes that are active
and (se.is_user_process <> 0 OR (rq.status = 'background' and se.status <> 'sleeping'))
--and rq.session_id NOT IN (@@SPID)
and DB_Name(rq.database_id) NOT IN ('BizTalkMsgBoxDb')
ORDER BY 3 desc 

END TRY 
BEGIN CATCH
	SELECT 'An Error has occurred and been caught'

SELECT rq.session_id as spid, 
CASE WHEN rq.command IN ('SELECT','UPDATE','DELETE','INSERT','WAITFOR','MERGE') THEN ''
	ELSE rq.command END as c,
	CONVERT(decimal(15,1),datediff(MILLISECOND, rq.start_time, getdate())/1000.) as dur_s,
	DB_Name(rq.database_id) as DBN,
	OBJECT_NAME(txt.objectid,txt.dbid) as oName,

	-- only present up here for troubleshooting... real loc is at the end of the column list
	txt.text as BatchText,
	rq.statement_start_offset,
    rq.statement_end_offset, 
    DATALENGTH(txt.text),
	/*
	CASE WHEN rq.statement_start_offset = 0 THEN 
			CASE WHEN rq.statement_end_offset = 0 AND DATALENGTH(txt.text) < 2000 
					THEN txt.text 
				WHEN rq.statement_end_offset = 0 AND DATALENGTH(txt.text) >= 2000 
					THEN SUBSTRING(txt.text, 1, 2000)
				WHEN rq.statement_end_offset = -1
					THEN txt.text 
				ELSE SUBSTRING(txt.text, 1, rq.statement_end_offset/2 + 1) 
			END 
		ELSE SUBSTRING(txt.text, (rq.statement_start_offset/2)+1, 
        ((CASE rq.statement_end_offset
          WHEN -1 THEN DATALENGTH(txt.text)
         ELSE rq.statement_end_offset
         END - rq.statement_start_offset)/2) + 1) 
         END AS StmtText,
        */
	CASE WHEN rq.wait_type IS NOT NULL AND rq.wait_type <> 'CXPACKET' AND rq.status <> 'suspended' THEN se.status
		WHEN wait_type IS NULL AND se.status <> 'running' THEN rq.status 
		ELSE '' END as s, 
	se.status,
	--blocking info
	rq.blocking_session_id as blk, convert(decimal(14,2),rq.wait_time/1000.) as wtSec, 
	CASE WHEN isnull(rq.wait_type, '<null>') <> isnull(rq.last_wait_type,'<null>')
		THEN rq.wait_type + ' (last: ' + rq.last_wait_type + ')'
		ELSE rq.wait_type END as wtTyp, 
	rq.wait_resource as wtRes, 

	--resource utilization
	convert(decimal(14,2),rq.cpu_time/1000.) as cpuT, 
	case when rq.granted_query_memory = 0 then CONVERT(decimal(14,1), -1)
		else convert(decimal(14,1),rq.granted_query_memory*8192./1024./1024.) end as qryMemMB,
	rq.logical_reads as LRds, rq.reads as PRds, rq.writes as Wr,  

	--resource history
	se.cpu_time as tCpuTm, 
	convert(decimal(14,2),se.total_scheduled_time/1000.) as tSchedTm, 
	convert(decimal(14,2),se.total_elapsed_time/1000.) as tElapTm,
	se.reads as totPRds, se.logical_reads as totLRds,se.writes as totWr, 
	se.memory_usage, --is this memory_usage field even worth including?

	--transaction info
	rq.open_transaction_count as OpenTrnCnt, rq.open_resultset_count as OpenRScnt, rq.transaction_id as TranID, 
	rq.transaction_isolation_level as IsoLvl,
	rq.lock_timeout as LckTmOt, rq.deadlock_priority as DLckPri,
	se.transaction_isolation_level as SessIso, se.lock_timeout as SessLckTmOt, se.deadlock_priority as SessDLckPri,

	--SQLOS
	rq.scheduler_id as Sched, rq.group_id as RGgrp, cn.node_affinity,

	--Activity History
	se.last_request_start_time, last_request_end_time, cn.last_read, cn.last_write,
	cn.num_reads, cn.num_writes, cn.most_recent_sql_handle,

	--Connection/Session Basic Info
	cn.connect_time, cn.client_net_address, cn.client_tcp_port, 
		--se.database_id as SessDBID only in SQL2012,
		--se.open_transaction_count as SessOpenTranCnt only in SQL2012, 

	--Connection Detailed Info
	 cn.local_net_address, cn.local_tcp_port, cn.net_transport, cn.protocol_type,
	  cn.endpoint_id as CnEndPntId, se.endpoint_id as sessEndPntId, 
	cn.net_packet_size, 
	se.host_name,se.host_process_id, se.program_name,  se.client_version, se.client_interface_name,
	 cn.most_recent_session_id, 
	 cn.connection_id, cn.parent_connection_id, 
	  
	--security info
	se.login_time, se.security_id, se.login_name, se.original_login_name, cn.encrypt_option, cn.auth_scheme,
	--se.authenticating_database_id only in SQL2012, 
	rq.user_id as DBUserID,

	--misc
	rq.percent_complete, rq.row_count as RowCnt, rq.nest_level, 
	se.row_count as SessRowCnt, rq.executing_managed_code, rq.start_time,

 	1
 	--,qp.query_plan
	--rq.task_address, 
FROM sys.dm_exec_requests rq
	inner join sys.dm_exec_sessions se 
		on rq.session_id = se.session_id
	inner join sys.dm_exec_connections cn
		on rq.connection_id = cn.connection_id
	outer apply sys.dm_exec_sql_text(rq.sql_handle) txt
	--outer apply sys.dm_exec_query_plan(rq.plan_handle) qp
WHERE 1=1
	--we want only user processes or background processes that are active
and (se.is_user_process <> 0 OR (rq.status = 'background' and se.status <> 'sleeping'))
and rq.session_id NOT IN (@@SPID)
and DB_Name(rq.database_id) NOT IN ('BizTalkMsgBoxDb')
ORDER BY 3 desc 

END CATCH
--dbcc inputbuffer(205)
