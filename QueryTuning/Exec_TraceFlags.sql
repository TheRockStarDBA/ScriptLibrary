USE <dbname> 
GO


SET STATISTICS XML ON
GO

<paste query here>

OPTION (RECOMPILE
		--MAXDOP X,
		,querytraceon 3604


		--,querytraceon 272				--causes a log record to be generated for each identity record generated

		--,querytraceon 610				--enables minimal logging in some circumstances

		--,querytraceon 611				--writes each lock escalation to the error log

		--,querytraceon 1200			--prints detailed lock information as every request for a lock is made

		--,querytraceon 1211			--disables lock escalation based on memory pressure or based on # of locks

		--,querytraceon 1229			-- disables lock partitioning among schedulers

		--,querytraceon 1224			--disables lock escalation based on # of locks, but NOT based on memory pressure

		--,querytraceon 1236			-- partitions the DATABASE lock type to help reduce contention on internal locking structures.

		--,querytraceon 8755			--disables locking hints, letting the optimizer/query execution engine to decide on the locking level

		--,querytraceon 4199
			--also: 4101, 4102 (and 4118), 4103, 4104, 4105, 4106, 4107, 4108, 4109, 4110, 4111, 4115, 4116, 4117, 4119, 4120, 4121, 4122,
			--		4124, 4125, 4126, 4127, 4128, 4129, 4131, 4133, 4135
			--		mostly for older versions: 168, 210, 212, 698, 2430, 2470, 4123, 4130, 9082, 

		--,querytraceon 8001			-- allows sys.dm_os_wait_stats to display some normally-hidden wait types

		--,querytraceon 652				--disables IO read-ahead across the whole instance. (Prob won't work with querytraceon)
		--									-- 652, 8744, and other flags have similarities. See my TF document for more details & links
		--,querytraceon 670 or 671		--disable deferred deallocation
		--,querytraceon 840				--"whenever a single page read is done and the BP hasn’t come close to its target size, any single-page read is 
										-- turned into a read of the extent that contains the page. Note that the TF is only needed for non-Ent/Dev/Eval editions"
		--,querytraceon 834				-- enables (if possible) Large Pages
		--,querytraceon 835				-- disables use of Locked Page memory model
		--,querytraceon 851				-- disables Buffer Pool Extensions even if enabled via ALTER SERVER

		--,querytraceon 1118			-- only uniform extents used during allocation

		--,querytraceon 1197			--prevent allocation of TempDB pages (by work tables) from being pulled from a work table cache

		--,querytraceon 2330			--disables the gathering/updating of sys.db_index_usage_stats and sys.dm_db_missing_index_group_stats

		--,querytraceon 3917			-- "According to Bob Ward’s PASS 2014 SQL Server IO talk, enables trace output (3605 is required) for 
										--  the Eager Write functionality that is used with bulk logged operations (such as SELECT INTO)"

		--,querytraceon 3940			-- "According to Bob Ward’s PASS 2014 SQL Server IO talk, forces the Eager Write functionality to 
										-- throttle at 1024 outstanding eager writes."

		--,querytraceon	6498			-- Modifies the compilation gateway threshold for the “big” gateway. Normally, only 1 “big gateway” query 
										-- compilation can occur at a time, but when this TF is enabled the formula is changed slightly

		--,querytraceon 6530			-- "FIX: Slow performance in SQL Server 2012 or SQL Server 2014 when you build an index on a spatial data type of a large table."
		--,querytraceon 6531			-- "Enables adjustment in the SQLOS scheduling layer to handle queries that issue many short-duration calls 
										-- to spatial data (which is implemented via CLR functions). MSFT: 'Only use this trace flag if the individual, 
										--	spatial method invocations (per row and column) take less than ~4ms. Longer invocations without preemptive 
										--	protection could lead to scheduler concurrency issues and SQLCLR punishment messages logged to the error log.'"

		--,querytraceon 6533			-- "improves performance of query operations with spatial data types in SQL Server 2012 and 2014. The performance 
										-- gain will vary, depending on the configuration, the types of queries, and the objects." See the warning in my TF doc.
		--,querytraceon 6534			-- "For perf issue when creating large LineString [Spatial] types"

		--,querytraceon 7357			-- Outputs info re: hashing operators, including role reversal, recursion levels, whether the Unique Hash optimization could be used, 
										-- info about the hash-related bitmap, etc. Dima’s article is a must-read.
										-- For parallel query plans, 7357 does NOT send output to the console window. However, output to the SQL Server error log can be enabled by enabling 3605.

		--,querytraceon 8002			--when CPUs are bit-masked (to enable only a subset) normally this fixes a scheduler to a CPU. Enabling this flag
										-- lets schedulers in a bit-masked config move around across different CPUs.

		--,querytraceon 8008			-- always use least-loaded scheduler (rather than attempting to use the last-used scheduler for a session)

		--,querytraceon 8015			--direct a NUMA SQL Server to pretend it is SMP

		--,querytraceon 8016			--Force new tasks to always be assigned to the preferred scheduler for a connection.

		--,querytraceon 8048			--For memory objects (CMemObj) that are already partitioned by Node, enabling this (startup-only) flag causes 
										-- them to be partitioned by CPU instead, which can reduce CMEMTHREAD and SOS_SUSPEND_QUEUE waits in some circumstances.

		--,querytraceon 8903			--Allows SQL Server to use a specific  API (SetFileIoOverlappedRange) when Locked Pages in Memory is enabled. 

		--,querytraceon 9348			-- Sets a row limit (based on cardinality estimates) that controls whether a bulk insert is attempted or not (assuming conditions are met for a 
										-- bulk insert). Introduced as a workaround for memory errors encountered with bulk insert.


		--,querytraceon 646				-- Describes (to the SQL error log, 3605 is required) which segment were eliminated in a columnstore query.
		--,querytraceon 1504			-- Prints info to the console (w/3604) or the error log (w/3605; required for parallel index builds) when an index DDL command requires 
										-- more memory to be granted in order to continue sorting rows in memory.

		--,querytraceon 2466			-- When SQL Server is determining the runtime DOP for a parallel plan, this flag directs it to use logic found in “older versions” (the post doesn’t say 
										-- which versions) to determine which NUMA node to place the parallel plan on. This older logic relies on a polling mechanism (roughly every 1 second), 
										-- and can result in race conditions where 2 parallel plans end up on the same node. The newer logic “significantly reduces” the likelihood of this happening.

		--,querytraceon 2467			-- “If target MAXDOP target is less than a single node can provide and if trace flag 2467 is enabled attempt to locate least loaded node”

		--,querytraceon 2468			-- “Find the next node that can service the DOP request.
										-- Unlike full mode, the global, resource manager keeps track of the last node used.   Starting from the last position, and moving to the 
										-- next node, SQL Server checks for query placement opportunities.  If a node can’t support the request SQL Server continues advancing nodes and searching.”

		--,querytraceon 2479			-- When SQL Server is determining the runtime DOP for a parallel plan, this flag directs it to limit the NUMA Node placement for the query to the node 
										-- that the connection is associated with.

		--,querytraceon 2486			-- In SQL 2016 (CTP 3.0 at least), enables output for the “query_trace_column_values” Extended Event, allowing the value of output columns from 
										-- individual plan iterators to be traced.

		--,querytraceon 9389			-- “Enables dynamic memory grant for batch mode operators. If a query does not get all the memory it needs, it spills data to tempdb, incurring 
										-- additional I/O and potentially impacting query performance. If the dynamic memory grant trace flag is enabled, a batch mode operator may ask 
										-- for additional memory and avoid spilling to tempdb if additional memory is available.”

		--,querytraceon 7357			-- Outputs info re: hashing operators, including role reversal, recursion levels, whether the Unique Hash optimization could be used, 
										-- info about the hash-related bitmap, etc. Dima’s article is a must-read.
										-- For parallel query plans, 7357 does NOT send output to the console window. However, output to the SQL Server error log can be enabled by enabling 3605.

--,querytraceon 7470			-- Fixes a problem where under certain (unknown) conditions, a sort spill occurs for large sorts
		);


SET STATISTICS XML OFF
GO 
