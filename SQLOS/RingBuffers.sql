/*
	obtained from this site: http://sqlserverpedia.com/blog/sql-server-2005/201/

possible types of notifications

RING_BUFFER_RESOURCE_MONITOR - memory state changes due to various types of memory pressure 
RING_BUFFER_MEMORY_BROKER - notification to components by memory broker advising them to grow, shrink or stay stable 
RING_BUFFER_SINGLE_PAGE_ALLOCATOR - when the Buffer Pool single page allocator turns on/off internal memory pressure 
RING_BUFFER_OOM - out-of-memory conditions 
RING_BUFFER_BUFFER_POOL - severe buffer pool failures, including buffer pool out-of-memory conditions 
RING_BUFFER_SCHEDULER - scheduler operations 
RING_BUFFER_SCHEDULER_MONITOR - scheduler health 
RING_BUFFER_EXCEPTION - list of exceptions 
RING_BUFFER_CLRAPPDOMAIN - state of AppDomains loaded in the system 
RING_BUFFER_SECURITY_ERROR - (new in SQL Server 2005 SP2) Windows API failure information 

Here are Bob Dorr's descriptions from this blog post:
http://blogs.msdn.com/b/psssql/archive/2009/03/13/sql-server-2008-ring-buffer-entries.aspx

RING_BUFFER_RESOURCE_MONITOR - Resource Monitor activity like was physical memory pressure signaled or not. 
RING_BUFFER_SCHEDULER_MONITOR  - What is the state of the logical schedulers, the health record type is very helpful. 
RING_BUFFER_MEMORY_BROKER  - Actions the internal memory broker is taking to balance the memory between caches. 
RING_BUFFER_SECURITY_ERROR  - Errors that occur during security operations.  Ex: login failed may have more details about the OS error code and such 
RING_BUFFER_SCHEDULER - Actual scheduler activity such as context switching.  You can reconstruct the execution order from these entries. 
RING_BUFFER_EXCEPTION - Any exceptions encountered in the server.  SQL uses throw internally for errors so you can see SQL errors as well. 
RING_BUFFER_CONNECTIVITY - Core connectivity information - useful in tracking down connection failure information
*/

/* Resource Monitor 
The following content is pulled from here: 
http://blogs.msdn.com/b/psssql/archive/2009/09/17/how-it-works-what-are-the-ring-buffer-resource-monitor-telling-me.aspx

The RM record has 3 major components showing various memory details.  
	The <RESOURCEMONITOR> portion of the record is handled from the local resource monitor.   You have a RM per scheduling node.  
	The <MEMORYNODE> details are from the memory node association or the RM.
	The <MEMORYRECORD> comes from global state information.  
The key for understanding why RM is running is in the ResourceMonitor section of the output.   This can be broken down into the Notification, Indicators and Effects.  

	Notification field: Considered the broadcasted notification state.      
		RESOURCE_MEMPHYSICAL_HIGH - SQL can grow memory usage
		RESOURCE_MEMPHYSICAL_LOW - System or internal physical memory - shrink
		RESOURCE_MEM_STEADY 
		RESOURCE_MEMVIRTUAL_LOW  –  Virtual address range for SQL Server process is becoming exhausted. Commonly the largest free block is less than 4MB.
	Note that there are 2 Indicators field (my query below is based on 2005, which only had 1 indicators field).
		IndicatorsProcess field: Process wide indicator using an |= of the following values 
		IDX_MEMPHYSICAL_HIGH = 1
		IDX_MEMPHYSICAL_LOW = 2
		IDX_MEMVIRTUALL_LOW = 4

		IndicatorsSystem field: System wide indicator an |= of the following values.
		IDX_MEMPHYSICAL_HIGH = 1
		IDX_MEMPHYSICAL_LOW = 2
		IDX_MEMVIRTUALL_LOW = 4 

		He adds some info on the SystemIndicators field: This state [the system-wide indicator] is often the windows memory notifications unless an override occurs because of the the EFFECT information.
		He gives some info on the EFFECT information, (which he later equates to the working set of the SQL process) but this info doesn't fully make sense to me 
			"Type = indicator type 
			State = current effect state  (ON, OFF or IGNORE are valid states) 
			Reversed= this maps to an applied state that toggles from 0 or 1 based on if the effect has been applied.  Applied indicates that the memory state has broadcast and we have achieved somewhat of a steady state for this indicator.  
			Value = duration that the effect has been in the reported state."

		More on EFFECTS: "The Effects represent the state SQL thinks it is in by looking at the working set size and basic memory targets.   The EFFECT logic is used during system level checks.   For example the RM can look at the physical memory and it shows high but the effects indicate Windows paged SQL Server out so the high should be ignored so we don’t consume more memory and cause more paging.    The effects logic can be disabled using a startup trace flag –T8020 to avoid honoring the memory effects.   This might be an option on the servers to narrow down what can trigger RM to execute as long as the working sets of the SQL Server instances are running steady with the target memory but it should only be used for troubleshooting purposes."

	The NodeID field: which Memory Node (i.e. which Resource Monitor) this occurred on.


Here's an example record: Bob notes that since it isn't system-wide, how can there be a "Low Physical Memory" state? He answers that
you'd need to look at the Memory Broker ring buffer entries as well, to see that Memory Broker is saying that a specific cache's
predicted usage is going to exceed internal targets and we need to start doing cache cleanup. You could tie this in with the Clock Hands
DMV to see which caches got cleaned up as a result of this request, or you could look at the DBCC MEMORYSTATUS command to look at the
Last Notification status as well. His post shows how to interpret the DBCC MEMORYSTATUS output here.
<ResourceMonitor>
	<Notification>RESOURCE_MEMPHYSICAL_LOW</Notification>  <---------------- Current notification state being broadcast to clerks
	<IndicatorsProcess>2</IndicatorsProcess>   <-----------------------   Indicator applies to the process as low physical memory
	<IndicatorsSystem>0</IndicatorsSystem> <-----------------------  0 means it is NOT a system wide indicator situation
	<NodeId>0</NodeId>
	<Effect type="APPLY_LOWPM" state="EFFECT_OFF" reversed="0">0</Effect>
	<Effect type="APPLY_HIGHPM" state="EFFECT_IGNORE" reversed="0">128163281</Effect>
	<Effect type="REVERT_HIGHPM" state="EFFECT_OFF" reversed="0">0</Effect>
</ResourceMonitor>  

In the comments of his post, he responds to a question from a consultant with some more good information.
*/


This query by Karthik gives some more columns (http://mssqlwiki.com/2012/06/27/a-significant-part-of-sql-server-process-memory-has-been-paged-out/)

SELECT CONVERT (varchar(30), GETDATE(), 121) as [RunTime],
dateadd (ms, (rbf.[timestamp] - tme.ms_ticks), GETDATE()) as [Notification_Time],
cast(record as xml).value('(//Record/ResourceMonitor/Notification)[1]', 'varchar(30)') AS [Notification_type],
cast(record as xml).value('(//Record/MemoryRecord/MemoryUtilization)[1]', 'bigint') AS [MemoryUtilization %],
cast(record as xml).value('(//Record/MemoryNode/@id)[1]', 'bigint') AS [Node Id],
cast(record as xml).value('(//Record/ResourceMonitor/IndicatorsProcess)[1]', 'int') AS [Process_Indicator],
cast(record as xml).value('(//Record/ResourceMonitor/IndicatorsSystem)[1]', 'int') AS [System_Indicator],
cast(record as xml).value('(//Record/ResourceMonitor/Effect/@type)[1]', 'varchar(30)') AS [type],
cast(record as xml).value('(//Record/ResourceMonitor/Effect/@state)[1]', 'varchar(30)') AS [state],
cast(record as xml).value('(//Record/ResourceMonitor/Effect/@reversed)[1]', 'int') AS [reserved],
cast(record as xml).value('(//Record/ResourceMonitor/Effect)[1]', 'bigint') AS [Effect],
 
cast(record as xml).value('(//Record/ResourceMonitor/Effect[2]/@type)[1]', 'varchar(30)') AS [type],
cast(record as xml).value('(//Record/ResourceMonitor/Effect[2]/@state)[1]', 'varchar(30)') AS [state],
cast(record as xml).value('(//Record/ResourceMonitor/Effect[2]/@reversed)[1]', 'int') AS [reserved],
cast(record as xml).value('(//Record/ResourceMonitor/Effect)[2]', 'bigint') AS [Effect],
 
cast(record as xml).value('(//Record/ResourceMonitor/Effect[3]/@type)[1]', 'varchar(30)') AS [type],
cast(record as xml).value('(//Record/ResourceMonitor/Effect[3]/@state)[1]', 'varchar(30)') AS [state],
cast(record as xml).value('(//Record/ResourceMonitor/Effect[3]/@reversed)[1]', 'int') AS [reserved],
cast(record as xml).value('(//Record/ResourceMonitor/Effect)[3]', 'bigint') AS [Effect],
 
cast(record as xml).value('(//Record/MemoryNode/ReservedMemory)[1]', 'bigint') AS [SQL_ReservedMemory_KB],
cast(record as xml).value('(//Record/MemoryNode/CommittedMemory)[1]', 'bigint') AS [SQL_CommittedMemory_KB],
cast(record as xml).value('(//Record/MemoryNode/AWEMemory)[1]', 'bigint') AS [SQL_AWEMemory],
cast(record as xml).value('(//Record/MemoryNode/SinglePagesMemory)[1]', 'bigint') AS [SinglePagesMemory],
cast(record as xml).value('(//Record/MemoryNode/MultiplePagesMemory)[1]', 'bigint') AS [MultiplePagesMemory],
cast(record as xml).value('(//Record/MemoryRecord/TotalPhysicalMemory)[1]', 'bigint') AS [TotalPhysicalMemory_KB],
cast(record as xml).value('(//Record/MemoryRecord/AvailablePhysicalMemory)[1]', 'bigint') AS [AvailablePhysicalMemory_KB],
cast(record as xml).value('(//Record/MemoryRecord/TotalPageFile)[1]', 'bigint') AS [TotalPageFile_KB],
cast(record as xml).value('(//Record/MemoryRecord/AvailablePageFile)[1]', 'bigint') AS [AvailablePageFile_KB],
cast(record as xml).value('(//Record/MemoryRecord/TotalVirtualAddressSpace)[1]', 'bigint') AS [TotalVirtualAddressSpace_KB],
cast(record as xml).value('(//Record/MemoryRecord/AvailableVirtualAddressSpace)[1]', 'bigint') AS [AvailableVirtualAddressSpace_KB],
cast(record as xml).value('(//Record/@id)[1]', 'bigint') AS [Record Id],
cast(record as xml).value('(//Record/@type)[1]', 'varchar(30)') AS [Type],
cast(record as xml).value('(//Record/@time)[1]', 'bigint') AS [Record Time],
tme.ms_ticks as [Current Time]
FROM sys.dm_os_ring_buffers rbf
cross join sys.dm_os_sys_info tme
where rbf.ring_buffer_type = 'RING_BUFFER_RESOURCE_MONITOR' --and cast(record as xml).value('(//Record/ResourceMonitor/Notification)[1]', 'varchar(30)') = 'RESOURCE_MEMPHYSICAL_LOW'
ORDER BY rbf.timestamp desc



select dateadd (ms, convert(bigint,ss.[notificationtime]) - sys.ms_ticks, getdate()) as record_time,ss.*
from (
SELECT mxml.value('(//Record/@time)[1]','bigint') as NotificationTime
,mxml.value('(//Record/ResourceMonitor/Notification)[1]','nvarchar(36)') as RM_Notification
,mxml.value('(//Record/ResourceMonitor/Indicators)[1]','int') as RM_Indicators
,mxml.value('(//Record/ResourceMonitor/NodeId)[1]','bigint') as RM_NodeID
,mxml.value('(//Record/MemoryNode/@id)[1]','bigint') as MemNode_ID
,mxml.value('(//Record/MemoryNode/ReservedMemory)[1]','bigint')/1024 as MemNode_Reserved_MB
,mxml.value('(//Record/MemoryNode/CommittedMemory)[1]','bigint')/1024 as MemNode_Committed_MB
,mxml.value('(//Record/MemoryNode/SharedMemory)[1]','bigint')/1024 as MemNode_Shared_MB
,mxml.value('(//Record/MemoryNode/AWEMemory)[1]','bigint')/1024 as MemNode_AWE_MB
,mxml.value('(//Record/MemoryNode/SinglePagesMemory)[1]','bigint')/1024 as MemNode_SinglePages_MB
,mxml.value('(//Record/MemoryNode/MultiplePagesMemory)[1]','bigint')/1024 as MemNode_MultiPages_MB
,mxml.value('(//Record/MemoryNode/CachedMemory)[1]','bigint')/1024 as MemNode_Cached_MB
,mxml.value('(//Record/MemoryRecord/MemoryUtilization)[1]','int')/1024 as Memory_Utilization_MB
,mxml.value('(//Record/MemoryRecord/TotalPhysicalMemory)[1]','bigint')/1024 as TotalPhysMemory_MB
,mxml.value('(//Record/MemoryRecord/AvailablePhysicalMemory)[1]','bigint')/1024 as AvailPhysMemory_MB
,mxml.value('(//Record/MemoryRecord/TotalPageFile)[1]','bigint')/1024 as TotalPF_MB
,mxml.value('(//Record/MemoryRecord/AvailablePageFile)[1]','bigint')/1024 as AvailPF_MB
,mxml.value('(//Record/MemoryRecord/TotalVirtualAddressSpace)[1]','bigint')/1024 as TotalVAS_MB
,mxml.value('(//Record/MemoryRecord/AvailableVirtualAddressSpace)[1]','bigint')/1024 as AvailVAS_MB
,mxml.value('(//Record/MemoryRecord/AvailableExtendedVirtualAddressSpace)[1]','bigint')/1024 as AvailExtendedVAS_MB
FROM (SELECT CAST([record] AS XML)
FROM [sys].[dm_os_ring_buffers]
WHERE [ring_buffer_type] = 'RING_BUFFER_RESOURCE_MONITOR') AS R(mxml)
) ss
cross join sys.dm_os_sys_info sys  
ORDER BY [NotificationTime] DESC

/* Memory Broker */

select dateadd (ms, convert(bigint,ss.[notificationtime]) - sys.ms_ticks, getdate()) as record_time,ss.*
from (
SELECT mxml.value('(//Record/@time)[1]','bigint') as NotificationTime
,mxml.value('(//Record/MemoryBroker/DeltaTime)[1]','bigint') as MemoryBroker_DeltaTime
,mxml.value('(//Record/MemoryBroker/Broker)[1]','nvarchar(100)') as MemoryBroker_BrokerName
,mxml.value('(//Record/MemoryBroker/Notification)[1]','nvarchar(100)') as MemoryBroker_Command
,mxml.value('(//Record/MemoryBroker/MemoryRatio)[1]','bigint') as MemoryBroker_MemoryRatio
,mxml.value('(//Record/MemoryBroker/NewTarget)[1]','bigint') as MemoryBroker_NewTarget
,mxml.value('(//Record/MemoryBroker/Overall)[1]','bigint') as MemoryBroker_Overall
,mxml.value('(//Record/MemoryBroker/Rate)[1]','bigint') as MemoryBroker_Rate
,mxml.value('(//Record/MemoryBroker/CurrentlyPredicted)[1]','bigint') as MemoryBroker_CurrentlyPredicted
,mxml.value('(//Record/MemoryBroker/CurrentlyAllocated)[1]','bigint') as MemoryBroker_CurrentlyAllocated
,mxml.value('(//Record/MemoryBroker/PreviouslyAllocated)[1]','bigint') as MemoryBroker_PreviouslyAllocated
FROM (SELECT CAST([record] AS XML)
		FROM [sys].[dm_os_ring_buffers]
		WHERE [ring_buffer_type] = 'RING_BUFFER_MEMORY_BROKER') AS R(mxml)
) ss
cross join sys.dm_os_sys_info sys  
ORDER BY [NotificationTime] DESC



/* Single-Page Allocator */

SELECT DATEADD(ms, CONVERT(BIGINT,ss.[notificationtime]) - sys.ms_ticks, GETDATE()) AS record_time,ss.*
FROM (
SELECT 
	mxml.value('(//Record/@time)[1]','bigint') as NotificationTime,
	mxml.value('(//Record/Pressure/@status)[1]','nvarchar(10)') as Pressure_Status,
	mxml.value('(//Record/Pressure/AllocatedPages)[1]','bigint') as AllocatedPages,
	mxml.value('(//Record/Pressure/AllAllocatedPages)[1]','bigint') as AllAllocatedPages,
	mxml.value('(//Record/Pressure/TargetPages)[1]','bigint') as TargetPages,
	mxml.value('(//Record/Pressure/AdjustedTargetPages)[1]','bigint') as AdjustedTargetPages,
	mxml.value('(//Record/Pressure/CurrentTime)[1]','bigint') as CurrentTime,
	mxml.value('(//Record/Pressure/DeltaTime)[1]','bigint') as DeltaTime,
	mxml.value('(//Record/Pressure/CurrentAllocationRequests)[1]','bigint') as CurrentAllocationRequests,
	mxml.value('(//Record/Pressure/DeltaAllocationRequests)[1]','bigint') as DeltaAllocationRequests,
	mxml.value('(//Record/Pressure/CurrentFreeRequests)[1]','bigint') as CurrentFreeRequests,
	mxml.value('(//Record/Pressure/DeltaFreeRequests)[1]','bigint') as DeltaFreeRequests
FROM (SELECT CAST([record] AS XML)
FROM sys.dm_os_ring_buffers
WHERE ring_buffer_type = 'RING_BUFFER_SINGLE_PAGE_ALLOCATOR') AS R(mxml)
) ss
CROSS JOIN sys.dm_os_sys_info sys


/* Scheduler Monitor */

SELECT DATEADD(ms, CONVERT(BIGINT,ss.[notificationtime]) - sys.ms_ticks, GETDATE()) AS record_time,ss.*
FROM (
SELECT 
	mxml.value('(//Record/@time)[1]','bigint') as NotificationTime,
	mxml.value('(//Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]','bigint') as SQLProcessorUtilizationPercent,
	mxml.value('(//Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]','bigint') as SystemIdlePercent,
	mxml.value('(//Record/SchedulerMonitorEvent/SystemHealth/UserModeTime)[1]','bigint') as SQLUserModeTime,
	mxml.value('(//Record/SchedulerMonitorEvent/SystemHealth/KernelModeTime)[1]','bigint') as SQLKernelModeTime,
	mxml.value('(//Record/SchedulerMonitorEvent/SystemHealth/PageFaults)[1]','bigint') as SQLPageFaults,
	mxml.value('(//Record/SchedulerMonitorEvent/SystemHealth/WorkingSetDelta)[1]','bigint') as SQLWorkingSetDelta,
	mxml.value('(//Record/SchedulerMonitorEvent/SystemHealth/MemoryUtilization)[1]','bigint') as SQLMemoryUtilization
FROM (SELECT CAST([record] AS XML)
FROM sys.dm_os_ring_buffers
WHERE ring_buffer_type = 'RING_BUFFER_SCHEDULER_MONITOR') AS R(mxml)
) ss
CROSS JOIN sys.dm_os_sys_info sys  


/* OOM - Out-of-Memory */

SELECT DATEADD(ms, CONVERT(BIGINT,ss.[notificationtime]) - sys.ms_ticks, GETDATE()) AS record_time,ss.*
FROM (
SELECT 
	mxml.value('(//Record/@time)[1]','bigint') as NotificationTime,
	mxml.value('(//Record/OOM/Action)[1]','nvarchar(50)') as OOM_Action,
	mxml.value('(//Record/OOM/Resources)[1]','bigint') as OOM_Resources
FROM (SELECT CAST([record] AS XML)
FROM sys.dm_os_ring_buffers
WHERE ring_buffer_type = 'RING_BUFFER_OOM') AS R(mxml)
) ss
CROSS JOIN sys.dm_os_sys_info sys  


/* Buffer Pool */
SELECT DATEADD(ms, CONVERT(BIGINT,ss.[notificationtime]) - sys.ms_ticks, GETDATE()) AS record_time,ss.*
FROM (
SELECT
	mxml.value('(//Record/@time)[1]','bigint') as NotificationTime,
	mxml.value('(//Record/BufferPoolFailure/@id)[1]','nvarchar(50)') as BufferPoolFailure,
	mxml.value('(//Record/BufferPoolFailure/CommittedCount)[1]','bigint') as CommittedCount,
	mxml.value('(//Record/BufferPoolFailure/CommittedTarget)[1]','bigint') as CommittedTarget,
	mxml.value('(//Record/BufferPoolFailure/FreeCount)[1]','bigint') as FreeCount,
	mxml.value('(//Record/BufferPoolFailure/HashedCount)[1]','bigint') as HashedCount,
	mxml.value('(//Record/BufferPoolFailure/StolenCount)[1]','bigint') as StolenCount,
	mxml.value('(//Record/BufferPoolFailure/ReservedCount)[1]','bigint') as ReservedCount
FROM (SELECT CAST([record] AS XML)
FROM sys.dm_os_ring_buffers
WHERE ring_buffer_type = 'RING_BUFFER_BUFFER_POOL') AS R(mxml)
) ss
CROSS JOIN sys.dm_os_sys_info sys
ORDER BY [NotificationTime] DESC



/* Connectivity Ring Buffer */
/* See this post
http://blogs.msdn.com/b/sql_protocols/archive/2008/05/20/connectivity-troubleshooting-in-sql-server-2008-with-the-connectivity-ring-buffer.aspx 
*/
SELECT 
	record.value('(Record/@id)[1]', 'int') as id,
	record.value('(Record/@type)[1]', 'varchar(50)') as type,
	record.value('(Record/ConnectivityTraceRecord/RecordType)[1]', 'varchar(50)') as RecordType,
	record.value('(Record/ConnectivityTraceRecord/RecordSource)[1]', 'varchar(50)') as RecordSource,
	record.value('(Record/ConnectivityTraceRecord/Spid)[1]', 'int') as Spid,
	record.value('(Record/ConnectivityTraceRecord/SniConnectionId)[1]', 'uniqueidentifier') as SniConnectionId,
	record.value('(Record/ConnectivityTraceRecord/SniProvider)[1]', 'int') as SniProvider,
  record.value('(Record/ConnectivityTraceRecord/OSError)[1]', 'int') as OSError,
  record.value('(Record/ConnectivityTraceRecord/SniConsumerError)[1]', 'int') as SniConsumerError,
  record.value('(Record/ConnectivityTraceRecord/State)[1]', 'int') as State,
	record.value('(Record/ConnectivityTraceRecord/RemoteHost)[1]', 'varchar(50)') as RemoteHost,
	record.value('(Record/ConnectivityTraceRecord/RemotePort)[1]', 'varchar(50)') as RemotePort,
	record.value('(Record/ConnectivityTraceRecord/LocalHost)[1]', 'varchar(50)') as LocalHost,
	record.value('(Record/ConnectivityTraceRecord/LocalPort)[1]', 'varchar(50)') as LocalPort,
	record.value('(Record/ConnectivityTraceRecord/RecordTime)[1]', 'datetime') as RecordTime,
	record.value('(Record/ConnectivityTraceRecord/LoginTimers/TotalLoginTimeInMilliseconds)[1]', 'bigint') as TotalLoginTimeInMilliseconds,
	record.value('(Record/ConnectivityTraceRecord/LoginTimers/LoginTaskEnqueuedInMilliseconds)[1]', 'bigint') as LoginTaskEnqueuedInMilliseconds,
	record.value('(Record/ConnectivityTraceRecord/LoginTimers/NetworkWritesInMilliseconds)[1]', 'bigint') as NetworkWritesInMilliseconds,
	record.value('(Record/ConnectivityTraceRecord/LoginTimers/NetworkReadsInMilliseconds)[1]', 'bigint') as NetworkReadsInMilliseconds,
	record.value('(Record/ConnectivityTraceRecord/LoginTimers/SslProcessingInMilliseconds)[1]', 'bigint') as SslProcessingInMilliseconds,
	record.value('(Record/ConnectivityTraceRecord/LoginTimers/SspiProcessingInMilliseconds)[1]', 'bigint') as SspiProcessingInMilliseconds,
	record.value('(Record/ConnectivityTraceRecord/LoginTimers/LoginTriggerAndResourceGovernorProcessingInMilliseconds)[1]', 'bigint') as LoginTriggerAndResourceGovernorProcessingInMilliseconds,
	record.value('(Record/ConnectivityTraceRecord/TdsBuffersInformation/TdsInputBufferError)[1]', 'int') as TdsInputBufferError,
	record.value('(Record/ConnectivityTraceRecord/TdsBuffersInformation/TdsOutputBufferError)[1]', 'int') as TdsOutputBufferError,
	record.value('(Record/ConnectivityTraceRecord/TdsBuffersInformation/TdsInputBufferBytes)[1]', 'int') as TdsInputBufferBytes,
	record.value('(Record/ConnectivityTraceRecord/TdsDisconnectFlags/PhysicalConnectionIsKilled)[1]', 'int') as PhysicalConnectionIsKilled,
	record.value('(Record/ConnectivityTraceRecord/TdsDisconnectFlags/DisconnectDueToReadError)[1]', 'int') as DisconnectDueToReadError,
	record.value('(Record/ConnectivityTraceRecord/TdsDisconnectFlags/NetworkErrorFoundInInputStream)[1]', 'int') as NetworkErrorFoundInInputStream,
	record.value('(Record/ConnectivityTraceRecord/TdsDisconnectFlags/ErrorFoundBeforeLogin)[1]', 'int') as ErrorFoundBeforeLogin,
	record.value('(Record/ConnectivityTraceRecord/TdsDisconnectFlags/SessionIsKilled)[1]', 'int') as SessionIsKilled,
	record.value('(Record/ConnectivityTraceRecord/TdsDisconnectFlags/NormalDisconnect)[1]', 'int') as NormalDisconnect,
	record.value('(Record/ConnectivityTraceRecord/TdsDisconnectFlags/NormalLogout)[1]', 'nvarchar(20)') as NormalLogout
FROM
(	SELECT CAST(record as xml) as record
	FROM sys.dm_os_ring_buffers
	WHERE ring_buffer_type = 'RING_BUFFER_CONNECTIVITY') as tab
order by RecordTime Desc 


/* RING_BUFFER_SECURITY_ERROR  available in SQL 2005 SP2 */
-- from this page: http://blogs.msdn.com/b/psssql/archive/2008/03/24/how-it-works-sql-server-2005-sp2-security-ring-buffer-ring-buffer-security-error.aspx

/* From this same blog post, Bob Dorr answers a commenter who was seeing 0x7A errors.
Bob says that the message text for this is "The data area passed to a system call is too small."
This apparently results from a system API that allows data pointer parameters to be NULL in the API interface,
but actually requires the data pointer to point to a structure that is of a valid size.
SQL makes calls like this, but when it receives the error message, resubmits the API call.
In effect, then, Bob is saying to ignore these messages.

*/

/* Record format

<Record id="197" type="RING_BUFFER_SECURITY_ERROR" time="3552445157">
  <Error>
    <SPID>158</SPID>
    <APIName>NetValidatePwdPolicy</APIName>
    <CallingAPIName>CAPIPwdPolicyManager::ValidatePwdForLogin</CallingAPIName>
    <ErrorCode>0x89B</ErrorCode>
  </Error>
</Record>

*/

--Turn the <ErrorCode> value from hex to decimal, and then use this command to see
-- the error text associated with it: net helpmsg <decimal error code>

SELECT record.value('(Record/@id)[1]', 'int') as id,
	record.value('(Record/@type)[1]', 'varchar(50)') as type,
	record.value('(Record/Error/SPID)[1]', 'bigint') as SPID,
	record.value('(Record/Error/APIName)[1]', 'varchar(100)') as APIName,
	record.value('(Record/Error/CallingAPIName)[1]', 'varchar(250)') as CallingAPIName,
	record.value('(Record/Error/ErrorCode)[1]', 'varchar(50)') as ErrorCode
FROM 
(	SELECT CAST(record as xml) as record
	FROM sys.dm_os_ring_buffers
	WHERE ring_buffer_type = 'RING_BUFFER_SECURITY_ERROR') as tab
order by RecordTime Desc 




