--Formats lots of transaction-related info into more helpful display values

; WITH tranLocks (resType, resDBID, reqSess, reqMode, reqStat, numLocks) as 
(	select resType, resDBID, reqSess, reqMode, reqStat, count(*) as numLocks
	from (select CASE resource_type
		WHEN 'OBJECT' THEN 'OBJECT' WHEN 'ALLOCATION_UNIT' THEN 'OBJECT' WHEN 'HOBT' THEN 'OBJECT'
		WHEN 'PAGE' THEN 'PAGE' WHEN 'EXTENT' THEN 'PAGE' WHEN 'KEY' THEN 'ROW' WHEN 'RID' THEN 'ROW' ELSE 'OTHER' END as ResType,
	resource_database_id as ResDBID, request_session_id as reqSess, request_mode as reqMode, request_status as reqStat
	FROM sys.dm_tran_locks WHERE resource_type <> 'DATABASE' ) ss2
	GROUP BY resType, resDBID, reqSess, reqMode, reqStat)
select se.session_id, --se.transaction_descriptor		--BOL: Transaction identifier used by SQL Server when communicating with the client driver.
	t.transaction_id, t.transaction_uow as UOW,
	CASE WHEN t.name = 'user_transaction' THEN 'USERtran' ELSE t.name END as TrnName, 
	CASE WHEN datediff(d, t.transaction_begin_time, getdate()) = 0 THEN CONVERT(varchar(30), t.transaction_begin_time, 108)  
		ELSE CONVERT(varchar(30), t.transaction_begin_time) END as TrnBegin, 
	CASE WHEN datediff(d, ese.last_request_start_time, getdate()) = 0 THEN CONVERT(varchar(30), ese.last_request_start_time, 108)  
		ELSE CONVERT(varchar(30), ese.last_request_start_time) END as LstReqStrtTm, 
	CASE WHEN datediff(d, ese.last_request_end_time, getdate()) = 0 THEN CONVERT(varchar(30), ese.last_request_end_time, 108)  
		ELSE CONVERT(varchar(30), ese.last_request_end_time) END as LstReqEndTm,
	db_name(dbt.database_id) as dbn, dbt.database_transaction_begin_time as TrnDBBegin, --BOL: time the database entered into the tran (specifically, time the first log rec for this DB was written)
														--implies that the tran could have been running longer but in other DBs
														--does "NULL" mean that the DB is a part of a tran, but read-only in that tran?
	CASE t.transaction_type 
		WHEN 1 THEN 'RW' WHEN 2 THEN 'ReadOnly' WHEN 3 THEN 'Sys' WHEN 4 THEN 'Distr' END as TrnTyp, 
	CASE t.transaction_state			--remember, this is the state of the Tran FOR THIS DB, not overall.
		WHEN 0 THEN '<>Init' WHEN 1 THEN 'initNOTstarted' WHEN 2 THEN 'Active' 	
		WHEN 3 THEN 'Ended'			--used for Read-only transactions only
		WHEN 4 THEN 'DistrCOMMITbegun'	--BOL: " The commit process has been initiated on the distributed transaction. This is for distributed 
										--transactions only. The distributed transaction is still active but further processing cannot take place"
		WHEN 5 THEN 'Prepared'		--prepared state "waiting resolution" (BOL)
		WHEN 6 THEN 'COMMITTED' WHEN 7 THEN 'inROLLBACK' WHEN 8 THEN 'RolledBack'  End as TrnState, 
	CASE dbt.database_transaction_type 
		WHEN 1 THEN 'RW' WHEN 2 THEN 'ReadOnly' WHEN 3 THEN 'Sys' END as DBTrnTyp,
	CASE dbt.database_transaction_state			--remember, this is the state of the Tran FOR THIS DB, not overall.
		WHEN 1 THEN '<>Init'  WHEN 3 THEN 'initNOlog' 	--initialized, but no log records
		WHEN 4 THEN 'InitLog' 	--initialized, with at least some log records
		WHEN 5 THEN 'Prepared' WHEN 10 THEN 'COMMITTED'  WHEN 11 THEN 'RolledBack'  WHEN 12 THEN 'BeingCommitted'  End as DBTrnState, 
	(dbt.database_transaction_log_bytes_used + dbt.database_transaction_log_bytes_reserved + 
		dbt.database_transaction_log_bytes_used_system + dbt.database_transaction_log_bytes_reserved_system) as totalLogBytes, 
		s1.numObjLck, s2.numPgLck, s3.numRowLck, s4.numOthLck,
	CASE t.dtc_state 
		WHEN 1 THEN 'ACTIVE' WHEN 2 THEN 'PREPARED' WHEN 3 THEN 'COMMITTED' WHEN 4 THEN 'ABORTED' WHEN 5 THEN 'RECOVERED' END as dtcState, 
	is_local,		--1 = local; 0 = "Distributed transaction or an enlisted bound session transaction" (BOL)
	se.enlist_count, 
	se.is_enlisted, --BOL to the rescue: "Through bound sessions and distributed transactions, it is possible for a transaction to be running under more than 
	se.is_bound,	-- one session. In such cases, sys.dm_tran_session_transactions will show multiple rows for the same transaction_id, one for each session 
					-- under which the transaction is running. 

					--[Also,] By executing multiple requests in autocommit mode using multiple active result sets (MARS), it is possible to have more than 
					--one active transaction on a single session. In such cases, sys.dm_tran_session_transactions will show multiple rows for the same session_id, 
					--one for each transaction running under that session.
	dbt.database_transaction_log_record_count as logRecCnt, 
	dbt.database_transaction_log_bytes_used as logBytesUsed, 
	dbt.database_transaction_log_bytes_reserved as logBytesRsvd, 
	dbt.database_transaction_log_bytes_used_system as logBytesUsedSys,	--by the "System"
	dbt.database_transaction_log_bytes_reserved_system as logBytesRsvdSys --by the "System"
	--dbt.database_transaction_begin_lsn as BeginLSN, dbt.database_transaction_last_lsn as LastLSN, dbt.database_transaction_most_recent_savepoint_lsn as mostRecentSavePoint, 
	--dbt.database_transaction_lastrollback_lsn as lastRollback, dbt.database_transaction_next_undo_lsn as nextUndo
from sys.dm_tran_active_transactions t
	left outer join sys.dm_tran_database_transactions dbt on t.transaction_id = dbt.transaction_id 
	left outer join sys.dm_tran_session_transactions se on se.transaction_id = t.transaction_id
	left outer join sys.dm_exec_sessions ese  on se.session_id = ese.session_id
	outer apply (SELECT numLocks as numObjLck FROM tranLocks tl  WHERE tl.resDBID = dbt.database_id 
				AND tl.reqSess = se.session_id AND reqStat = 'GRANT' AND resType = 'OBJECT') s1
	outer apply (SELECT numLocks as numPgLck
				FROM tranLocks tl WHERE tl.resDBID = dbt.database_id 
				AND tl.reqSess = se.session_id AND reqStat = 'GRANT' AND resType = 'PAGE') s2
	outer apply (SELECT numLocks as numRowLck
				FROM tranLocks tl WHERE tl.resDBID = dbt.database_id 
				AND tl.reqSess = se.session_id AND reqStat = 'GRANT' AND resType = 'ROW') s3
	outer apply (SELECT numLocks as numOthLck
				FROM tranLocks tl WHERE tl.resDBID = dbt.database_id 
				AND tl.reqSess = se.session_id AND reqStat = 'GRANT' AND resType = 'OTHER') s4
where 1=1
--and t.transaction_id not in (select transaction_id from sys.dm_tran_current_transaction)
--and t.transaction_begin_time < dateadd(mi, -5, getdate())

and (t.transaction_type in (1, 2,  3, 4)	--"2" means read-only tran...exclude if they are getting in the way
	)
and (dbt.database_transaction_state <> 3 OR (ISNULL(numObjLck,0) + ISNULL(numPgLck,0) + ISNULL(numRowLck,0) + ISNULL(numOthLck,0) > 0 )
	) 
ORDER BY se.session_id, t.transaction_id, t.transaction_begin_time

