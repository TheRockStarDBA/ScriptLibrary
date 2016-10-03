USE <dbname> 
GO


SET SHOWPLAN_XML ON
GO

<paste query here>

OPTION (RECOMPILE
		,querytraceon 3604

		/* Non-granular model changes */
		--,querytraceon 2301			-- Makes your optimizer work harder by enabling advanced optimizations that are specific to decision support queries, applies to processing of large data sets.
		--,querytraceon 2312			-- enables new CE
		--,querytraceon 9481			-- force use of old CE
		--,querytraceon 4199





		/* Optimization phases & caching */
		--,MAXDOP X
		--,querytraceon 8649			-- Strongly encourages the optimizer to generate parallel plans
		--,querytraceon 8757			--Skip Trivial Plan optimization, essentially forcing entry into Full optimization for a query.
		--,querytraceon 8677			-- Skips “Search 1” phase of query optimization, and only Search 0 and Search 2 execute. 
		--,querytraceon 8671				-- According to Dima, disables the logic that prunes the memo and prevents the optimization process from stopping due to “Good Enough Plan found”. 
										-- Can significantly increase the amount of time, CPU, and memory used in the compilation process
		--,querytraceon 8675			-- Display query optimization phases, along with stats (timing, costs, etc) about each phase. 
		--,querytraceon 2372			--Ben Nevarez: “shows memory utilization during the different optimization stages.”

		--,querytraceon 205				--Randal-SQL-SDB407: “log plan recompilations and reasons for them”
										-- Banerjee2005: “Report when a stored procedure is being recompiled. This trace flag will write the corresponding message to the SQL Server errorlog”
		--,querytraceon 253				-- appears to prevent ad-hoc queries from being cached
		--,querytraceon 445				--"Full functionality unknown. Prints “Compile issued:” and then the text of the sql statement being compiled to the SQL error log. 
										-- Personally confirmed that this still works in SQL 2014 even though it appears to be a very old trace flag
		--,querytraceon 2318			--Aaron: stumbled onto this one as well. I’ve only seen one type of output so far: 
										-- “Optimization Stage:  HEURISTICJOINREORDER”. Maybe useful in combo with other compilation trace flags to 
										-- see the timing of join reordering?
		--,querytraceon 2861			-- KB: “Trace flag 2861 instructs SQL Server to keep zero cost plans in cache, which SQL Server would typically not cache 
										-- (such as simple ad-hoc queries, set statements, commit transaction and others).”





		/* Optimization trees */
		--,querytraceon 8605			-- Display the initial logical tree (the input into query optimization). (Paul also calls this the “converted tree” in Part 4 of his series)
		--,querytraceon 8606			-- Displays additional logical trees, including the Input Tree, the Simplified Tree, the “Join-collapsed” Tree, the 
										-- “Tree before Project Normalization”, and the “Tree after Project Normalization”
		--,querytraceon 8607			-- Displays the optimization output tree, before Post-optimization rewrite. Has a “Query marked as cachable” note if the plan can be cached.
		--,querytraceon 7352			-- The final query tree after Post-optimization re-write
		--,querytraceon 8612			-- Paul doesn’t give a description; I need to read the post carefully and infer my own
										-- The Dima link describes it as adding cardinality info to the various trees produced by flags 8605, 8606, and 8607.
		--,querytraceon 8621			-- PWhite: “Rule with resulting tree” (use with 8619)





		/* Memo flags */
		--,querytraceon 8608			-- initial memo
		--,querytraceon 8615			-- Show the final Memo structure
		--,querytraceon 8620			-- PWhite: “Add memo arguments to 8619”
		--,querytraceon 8739			-- Dima: “Group Optimization Info”





		/* Optimization Rules */
		--,querytraceon 2373			--Shows memory utilization before and after various optimizer rules are applied (e.g. IJtoIJsel). Appears to provide a way to “trace” what rules are used when optimizing a query.
		--,querytraceon 8609			-- PWhite: “Task and operation type counts”
		--,querytraceon 8619			--PWhite: “Apply rule with description”; Dima: “Show Applied Transformation Rules”
		--,querytraceon 8628			--When used with TF 8666, causes extra information about the transformation rules applied to be put into the XML showplan.





		/* Stat Object informational */
		--,querytraceon 8666			--Causes some useful info (including stat object thresholds) already present in the internal representation of a plan to be included in the XML plan output.
		--,querytraceon 8721			-- KB: This flag “dump[s] information into the error log when AutoStat has been run. The following is an example of the type of message that 
										-- you can expect to see:
										--		1998-10-14 16:22:13.21 spid13 AUTOSTATS: UPDATED Tbl: [authors]
										--		Rows: 23 Mods: 501 Bound: 500 Duration: 47ms UpdCount: 2
										-- For this message, ‘Mods’ is the total number of modifications to the table. ‘Bound’ is the modification threshold, ‘Duration’ is the amount 
										-- of time that the UPDATE STATISTICS statement required to complete, and ‘UpdCount’ is the count of updated statistics.”





		/* Stat Object affecting */
		--,querytraceon 2371			-- Switches the threshold for a performance-based recompile (for a given stats object) from the default of 20%+500 rows to SQRT(1000*<num rows in table>)
		--,querytraceon 2389			-- When SQL Server updates a stat object, it observes whether the max value in the lead column is larger than it was before
		--,querytraceon 2390			--Closely tied to 2389 and the ascending key problem. TF 4139 enables a fix (SQL 2012+) for some limitations of 2390
		--,querytraceon 4139			-- Enables a fix (in a CU) for SQL 2012 and SQL 2014 that fixes a limitation with TF 2389/2390 and the “ascending key” behavior, where if 90% of the 
										-- newly-inserted values were NOT higher than the highest key value, the column would not be marked “ascending”





		/* cardinality estimation informational */
		--,querytraceon 2363			-- For the new CE, outputs information regarding statistics information used and derived during the optimization process

		--,querytraceon 9204			-- Old CE: lists statistics that are fully loaded and used for cardinality estimation
		--,querytraceon 9292			-- Old CE: lists statistics whose header was loaded, indicating the optimizer found the stat object "potentially useful"






		/* cardinality estimation affecting */
		--,querytraceon 2324			-- Disables implied predicates
		--,querytraceon 2328			-- Ian Jose notes that in SQL 2000, cardinality estimates were not done for predicates that compared 2 constants (“constants” here includes 
										-- parameters or variables). In SQL 2005, this behavior changed, but could be undesirable under certain circumstances. TF 2328 reverts back to the SQL 2000 behavior. 
										-- In Dima’s post, he demonstrates that using TF 2328 leads to a selectivity “guess” (calling CScaop_Comp::GuessSelect). 
		--,querytraceon 2329			-- disables "few outer rows" optimization
		--,querytraceon 2453			-- Applies the familiar temp table rowcount recompilation thresholds to table variables, allowing us to potentially get better cardinality 
										-- estimates for queries that use table variables. Aaron Bertrand’s article is very helpful, and points out various caveats, such as the flag’s 
										-- ineffectiveness with QUERYTRACEON or trivial plans.
		--,querytraceon 4136			-- Disables parameter sniffing; equivalent to adding OPTIMIZE FOR UNKNOWN to all queries that reference a parameter
										-- Dima notes that 4136 has no impact on runtime constant sniffing
		--,querytraceon	4137			-- Modifies cardinality estimation for multiple, conjunctive (AND) predicates, such that the predicate with the lowest selectivity is used for 
										-- estimating the cardinality for the complete group of conjunctive predicates. Paul White’s article covers “Minimum Selectivity” quite well, and 
										-- notes that this flag does NOT work in SQL 2014 unless the pre-2014 cardinality estimator is enabled. Instead, TF 9471 should be used.
		--,querytraceon 4138			-- Turns off row-goal logic
		--,querytraceon 9471			-- Enables “Minimum Selectivity” cardinality estimation behavior for SQL 2014 under the new cardinality estimation model. Note that, unlike	
										-- TF 4137 (which only applied “Minimum Selectivity” for conjunctive predicates), 9471 applies it to both conjunctive and disjunctive predicates.
		--,querytraceon 9472			-- Assumes independence for multiple WHERE predicates in the SQL 2014 cardinality estimation model. Predicate independence was the default for 
										-- versions prior to SQL Server 2014, and thus this flag can be used to more closely emulate pre-SQL 2014 cardinality estimate behavior in a more 
										-- specific fashion than TF 9481.
		--querytraceon 9476				--Implements a “model variation” in the SQL 2014 cardinality estimator. In the new cardinality estimation model, the “base containment” approach is 
										-- used towards combining the selectivities of join filters with the “derived” statistics collections that result from child operators in the query plan. 
										-- In the pre-SQL 2014 cardinality estimation model, the “simple containment” approach was taken. This TF forces the new CE to use simple containment 
										-- instead of base containment. (Also, per Paul White: “ignores the histograms (avoiding coarse alignment) and simply assumes containment at the join”)
		--,querytraceon 9479			-- Dima: “forces the optimizer to use Simple Join algorithm even if a histogram is available…will force optimizer to use a simple join estimation 
										-- algorithm, it may be CSelCalcSimpleJoinWithDistinctCounts, CSelCalcSimpleJoin or CSelCalcSimpleJoinWithUpperBound, depending on the compatibility 
										-- level and predicate comparison type.” (Paul White: “uses simple containment instead of base containment for simple joins”)
		--,querytraceon 9482			-- Implements a “model variation” in the SQL 2014 cardinality estimator. The flag turns off the “overpopulated primary key” adjustment that the 
										-- optimizer might use when determining that a “dimension” table (the schema could be OLTP as well) has many more distinct values than the “fact” table. 
										-- (The seminal example is where a Date dimension is populated out into the future, but the fact table only has rows up to the current date). 
										-- Since join cardinality estimation occurs based on the contents of the histograms of the joined columns, an “overpopulated primary key” can result in 
										-- higher selectivity estimates, causing rowcount estimates to be too low.
		--,querytraceon 9483			-- Implements a “model variation” in the SQL 2014 cardinality estimator. The flag will force the optimizer to create (if possible) a filtered 
										-- statistics object based on a predicate in the query. This filtered stat object is not persisted and thus would be extremely resource intensive 
										-- for frequent compilations. In Dima’s example, the filtered stat object is actually created on the join column…i.e. 
										-- “CREATE STATISTICS [filtered stat obj] ON [table] (Join column) WHERE (predicate column = ‘literal’)”
		--,querytraceon 9488			-- Implements a “model variation” in the SQL 2014 cardinality estimator. This flag reverts the estimation behavior for multi-statement TVFs back to 
										-- 1 row (instead of the 100-row estimate behavior that was adopted in SQL 2014).
		--,querytraceon 9489			-- Implements a “model variation” in the SQL 2014 cardinality estimator and turns off the new logic that handles ascending keys. 





		/* Server resources */
		--,querytraceon 2315			--"Aaron: I stumbled onto this one. Seems to output memory allocations taken during the compilation process 
										-- (and maybe the plan as well? “PROCHDR”), as well as memory broker states & values at the beginning and end of compilation."
		--,querytraceon 2330			--disables the gathering/updating of sys.db_index_usage_stats and sys.dm_db_missing_index_group_stats
		--,querytraceon 2335			-- KB: “One of the factors that impacts the execution plan generated for a query is the amount of memory that is available for SQL Server. 
										-- In most cases SQL Server generates the most optimal plan based on this value, but occasionally it may generate an inefficient plan for a specific 
										-- query when you configure a large value for max server memory, thus resulting in a slow-running query… You can workaround the problem by using trace 
										-- flag T2335 as a startup parameter. This trace flag will cause SQL Server to generate a plan that is more conservative in terms of memory consumption 
										-- when executing the query. It does not limit how much memory SQL Server can use. The memory configured for SQL Server will still be used by data cache, 
										-- query execution and other consumers.”
		--,querytraceon 2336			--Aaron: Another one that I stumbled onto. Appears to tie memory info and cached page likelihoods with costing.





		/* Specific operators */
		--,querytraceon 610				--enables minimal logging in some circumstances
		--,querytraceon 2332			-- PWhite: “Force DML Request Sort (CUpdUtil::FDemandRowsSortedForPerformance)”
		--,querytraceon 2340			--Dima: “Disable Nested Loops Implicit Batch Sort on the Post Optimization Rewrite Phase”
										-- Read Dima’s article to understand how this TF and the behavior it controls differs from 8744 and 9115 and the behaviors they control.
		--,querytraceon 2441			--Enables the use of a hash join for joins to column store indexes even when the join clause would normally be removed “during query normalization”. 
		--,querytraceon 7357			-- Outputs info re: hashing operators, including role reversal, recursion levels, whether the Unique Hash optimization could be used, 
										-- info about the hash-related bitmap, etc. Dima’s article is a must-read.
										-- For parallel query plans, 7357 does NOT send output to the console window. However, output to the SQL Server error log can be enabled by enabling 3605.
		--,querytraceon 7359			-- Disables the bitmap associated with hash matching. This bitmap is used for “bit-vector filtering” and can reduce the amount of data written to 
										-- TempDB during hash spills.
		--,querytraceon 7470			-- Fixes a problem where under certain (unknown) conditions, a sort spill occurs for large sorts
		--,querytraceon 7497			-- Behavior and intended purpose unknown, but in this post Paul White uses it in concert with 7498 to disable “optimized bitmaps”.
		--,querytraceon 7498			-- ditto
		--,querytraceon 8633			-- PWhite: “Enable prefetch (CUpdUtil::FPrefetchAllowedForDML and CPhyOp_StreamUpdate::FDoNotPrefetch)”
		--,querytraceon 8666			-- Two PWhite posts use it to show whether a “Shared Rowset optimization” is in use
		--,querytraceon 8690			-- Prevents the optimizer from using "performance spools"
		--,querytraceon 8692			-- Force optimizer to use an Eager Spool for Halloween Protection
		--,querytraceon 8719			-- In SQL 2000, apparently would show IO prefetch on loop joins and bookmarks. I (Aaron) was unable to replicate the query plan behavior on 
										-- SQL 2012 using the same test, so this flag may be obsolete.
		--,querytraceon 8738			-- (Apparently) disables an optimization where rows are sorted before a Key Lookup operator. (The optimization is meant to promote Sequential IO 
										-- rather than the random nature of IO from Key Lookups). Note that the context in which this flag is described means that the above description 
										-- may not be very precise, or even the only use of this flag.
		--,querytraceon 8744			--KB: “Disables pre-fetching for the Nested Loops operator. Incorrect use of this trace flag may cause additional physical reads when SQL Server 
										-- executes plans that contain the Nested Loops operator… You can turn on trace flag 8744 at startup or in a user session. When you turn on trace 
										-- flag 8744 at startup, the trace flag has global scope. When you turn on trace flag 8744 in a user session, the trace flag has session scope.”

										--PWhite: “Disable prefetch (CUpdUtil::FPrefetchAllowedForDML)”
										-- See also this Paul White forum answer to see TF 8744 juxtaposed (and contrasted) with TF 652. Dima’s article, which is really about 
										-- “nested loop batch sorting” behavior, is useful to contrast NL prefetching and 8744 from NL batch sorting and 2340/9115.
		--,querytraceon 8746			--Whatever else it does, one effect is to disable the “rowset sharing” optimization described in the 2 PWhite posts.
		--,querytraceon 8758			--In Paul's first post, he simply states “A [workaround to the MERGE bug described] is to apply Trace Flag 8758 – unfortunately this disables a 
										-- number of optimisations, not just the one above, so it’s not really recommended for long term use.”
										-- In the second post, he describes it as “Disable rewrite to a single operator plan (CPhyOp_StreamUpdate::PqteConvert)”
		--,querytraceon 8790			--PWhite: “Undocumented trace flag 8790 forces a wide update plan for any data-changing query (remember that a wide update plan is always possible)”
		--,querytraceon 8795			--PWhite: “Disable DML Request Sort (CUpdUtil::FDemandRowsSortedForPerformance)”
		--,querytraceon 9115			--PWhite: “Disable prefetch (CUpdUtil::FPrefetchAllowedForDML)”
										-- Dima: “Disables both [NLoop Implicit Batch Sort {TF 2340} and NL Prefetching {TF 8744}], and not only on the Post Optimization, but the explicit Sort also”
		--,querytraceon 9130			--Inhibits the optimizer from pushing residual predicates down into “access method” iterators (i.e. seeks and scans). Can be helpful to see how many records the optimizer expects a seek to qualify, compared to the # of records that the residual predicate will qualify
										-- Ballantyne SQLBits: “Disable non-sargable pushed predicates”
		--,querytraceon 9347			--A mysterious flag mentioned nowhere else, but referenced in this bugfix KB: 
										-- “FIX: Can't disable batch mode sorted by session trace flag 9347 or the query hint QUERYTRACEON 9347 in SQL Server 2016”
		--,querytraceon 9348			-- Sets a row limit (based on cardinality estimates) that controls whether a bulk insert is attempted or not (assuming conditions are met for a 
										-- bulk insert). Introduced as a workaround for memory errors encountered with bulk insert.

		--,querytraceon 9349			--“Disables batch mode top sort operator. SQL Server 2016 introduces a new batch mode top sort operator that boosts 
										-- performance for many analytical queries.”

		--,querytraceon 9358			--Disables batch-mode sort operations

		--,querytraceon 9453			--Disables Batch Mode in Parallel Columnstore query plans. (Note that a plan using batch mode appears to require a recompile before the TF takes effect)

		--,querytraceon 6530			-- "FIX: Slow performance in SQL Server 2012 or SQL Server 2014 when you build an index on a spatial data type of a large table."
		--,querytraceon 6531			-- "Enables adjustment in the SQLOS scheduling layer to handle queries that issue many short-duration calls 
										-- to spatial data (which is implemented via CLR functions). MSFT: 'Only use this trace flag if the individual, 
										--	spatial method invocations (per row and column) take less than ~4ms. Longer invocations without preemptive 
										--	protection could lead to scheduler concurrency issues and SQLCLR punishment messages logged to the error log.'"

		--,querytraceon 6533			-- "improves performance of query operations with spatial data types in SQL Server 2012 and 2014. The performance 
										-- gain will vary, depending on the configuration, the types of queries, and the objects." See the warning in my TF doc.
		--,querytraceon 6534			-- "For perf issue when creating large LineString [Spatial] types"





		/* Other plan-affecting flags (children of 4199 or other bug-fix stuff) */
		--,querytraceon 4199
			--also: 4101, 4102 (and 4118), 4103, 4104, 4105, 4106, 4107, 4108, 4109, 4110, 4111, 4115, 4116, 4117, 4119, 4120, 4121, 4122,
			--		4124, 4125, 4126, 4127, 4128, 4129, 4131, 4133, 4135
			--		mostly for older versions: 168, 210, 212, 698, 2430, 2470, 4123, 4130, 9082, 
		--,querytraceon 4138			-- “A query may take a long time to run if the query optimizer uses the Top operator in SQL Server 2008 R2 or in SQL Server 2012.”
										-- Appears to fix significant cardinality estimation problems for certain TOP, semi-join, and FAST N queries.




		/* Miscellaneous */
		--,querytraceon 2398			--Another one I stumbled upon myself…outputs info about “Smart Seek costing”: 
										-- e.g.: “Smart seek costing (75.2) :: 1.34078e+154 , 1”

		--,querytraceon 8602			-- ignore index hints specified in the query

		

		




		)
	;

SET SHOWPLAN_XML OFF
GO 
