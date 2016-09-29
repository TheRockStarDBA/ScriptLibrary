select [CURRENT LSN], [Transaction ID], replace(Operation,'LOP_','') as Operation, 
	REPLACE(Context,'LCX_','') as Context, SPID,  [Transaction Name] as TranName, [Description],
	/*--???
	LogBlockGeneration, [Tag Bits], [Flag Bits],
	*/
	--page/row/structure affected
	 AllocUnitID, AllocUnitName, [Page ID], [Slot ID] as SlotID, [Previous Page LSN], 
	PartitionID, RowFlags, [Num Elements] as NumElements, [Offset in Row] as OffsetInRow, [Modify Size] as ModifySize, 
	[Rowbits First Bit], [Rowbits Bit Count], [Rowbits Bit Value], [Byte Offset], [New Value], [Old Value],
	--Lock info
	[Number of Locks] as NumLocks, [Lock Information] as LockInfo, 	
	[NewAllocUnitId],
	[PageFormat PageType], [PageFormat PageFlags], 
	[PageFormat PageLevel], [PageFormat PageStat], [PageFormat FormatOption], 
	/*
	--Checkpoint Information
	[Checkpoint Begin], [CHKPT Begin DB Version], [Max XDESID], [Num Transactions],
	[Checkpoint End], [CHKPT End DB Version], [Minimum LSN], [Dirty Pages], 
	*/
	/*
	--Replication info (for Checkpoint, I think)
	[Oldest Replicated Begin LSN], [Next Replicated End LSN], [Last Distributed Backup End LSN], [Last Distributed End LSN], 
	*/
	/*
	--Transaction information
	[Server UID],  [Beginlog Status], [Xact Type], [Begin Time],  [Transaction SID], 
	[Xact ID], [Xact Node ID], [Xact Node Local ID], [End Time], [Transaction Begin], 
	*/
	/*
	--More replication information
	[Replicated Records], [Oldest Active LSN], [Server Name], [Database Name], [Mark Name], [Master XDESID], [Master DBID], 
	[Preplog Begin LSN], 
	*/
	/*--???
	[Prepare Time], [Virtual Clock], [Previous Savepoint], [Savepoint Name], 
	*/
	/*
	--Transaction Statistics? or is this replication-related?
	[LSN before writes], [Pages Written], [Data Pages Delta], [Reserved Pages Delta], [Used Pages Delta], 
	[Data Rows Delta], [Command Type], 	[Partial Status], [Command], 
	 [New Split Page], [Rows Deleted], [Bytes Freed], 
	*/
	--more replication info
	--[Publication ID], [Article ID], 
	--????
	--[Cl TableId], [Cl Index Id], 
	/*
	--???
	 [FileGroup Id], [Meta Status] [File Status], 
	[File ID], [Physical Name], [Logical Name], [Format LSN], [RowsetID], 
	*/
	--Text info
	/*
	[TextPtr], [Column Offset], 
	[Flags], [Text Size], [Offset], [Old Size], [New Size],  
	*/
	--Bulk allocation info
	--[Bulk allocated extent count], [Bulk RowsetId], [Bulk AllocUnitId], 
	--[Bulk allocation first IAM Page ID], [Bulk allocated extent ids], 
	--Compression Information
	--[Compression Log Type], [Compression Info], 
	/*
	--Binary data (& actual Log Record bytes)
	[RowLog Contents 0], [RowLog Contents 1], [RowLog Contents 2], [RowLog Contents 3], [RowLog Contents 4], 
	[Log Record],
	*/
	--Log Record Sizing
	[Log Record Fixed Length] as LogRecFixedLen, [Log Record Length] as LogRecLen, [Log Reserve] as LogRsvd,  
	[Previous LSN], [CURRENT LSN]
from fn_dblog(null, null) 
where [Current LSN] >= '000000bb:0000005b:001b'



