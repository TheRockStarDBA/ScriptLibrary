--How I like to call WhoIsActive

exec sp_WhoIsActive @show_sleeping_spids=1, 
		@get_full_inner_text=0, 
		@get_outer_command=0,	--set to 1 to get InputBuffer
		@get_plans=0,			--1=stmt-only plan, 2=full plan
		@get_transaction_info=0,	--set to 1 to get Tlog write and Tran duration
		
		@get_locks=0,				--XML node with locks for the request... not something I'll use often
		@get_avg_time=0,			--only rarely useful for my needs
		@get_additional_info=0,		--most valuable stuff here is Tran Iso Level, Lock Timeout, Deadlock Priority, 
										--a SQL Agent subnode if the SPID is coming from a SQL Agent job, 
										--and, if the spid is blocked, a block_info subnode with lock resource info 
		@sort_order = '[start_time] ASC',
		@output_column_list = '[dd%][session_id][tasks][database_name][sql_text][sql_command][block%][wait_info][used_memory][cpu%][tempdb_curr%][tempdb_alloc%][tran_log%][tran_start_time][open_tran_count][reads%][writes%][physical%][context%][query_plan][locks][additional_info][login_name][program_name][collection_time]',
			--other relevant columns to add: [host_name], [request_id], [login_time]
		@delta_interval = 0,			--take 2 snapshots <x> seconds apart, then show the diff.
		@get_task_info=2,				--leave this as-is...too good to omit
		@find_block_leaders=0		

/*
TempDB, reads, writes, and physical% fields are in pages
used_memory is also in pages

Wait_Info field:
Aggregates wait information, in the following format:
	(Ax: Bms/Cms/Dms)E
		A is the number of waiting tasks currently waiting on resource type E. 
		B/C/D are wait times, in milliseconds. If only one thread is waiting, its wait time will be shown as B.
			If two tasks are waiting, each of their wait times will be shown (B/C). 
			If three or more tasks are waiting, the minimum, average, and maximum wait times will be shown (B/C/D).
		If wait type E is a page latch wait and the page is of a "special" type (e.g. PFS, GAM, SGAM),
			the page type will be identified.
		If wait type E is CXPACKET, the nodeId from the query plan will be identified
*/
