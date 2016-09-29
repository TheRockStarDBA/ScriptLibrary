--Memory Clerks that have allocated more than 128 kb of space, in descending order
--this will give us an idea of where SQL is putting its memory
--NOTE that this will not include external components that SQL can't track, such as COM+ objects via sp_OACreate, and Extended Stored Procs
--however, it should include hosted components like certain OLE DB providers, that interact with SQL's hosted components facility
-- (see sys.dm_os_hosts)
select [type], [name], memory_node_id as memNode, single_pages_kb, multi_pages_kb, virtual_memory_reserved_kb as VMReservedKB, 
	virtual_memory_committed_kb as VMCommittedKB, awe_allocated_kb,
	shared_memory_reserved_kb as SMReservedKB, shared_memory_committed_kb as SMCommittedKB, page_size_Bytes, page_allocator_address
from sys.dm_os_memory_clerks
where (single_pages_kb+multi_pages_kb+virtual_memory_reserved_kb+shared_memory_reserved_kb) > 128
order by (single_pages_kb+multi_pages_kb+virtual_memory_reserved_kb+shared_memory_reserved_kb) desc


--For those memory clerks that were returned by the above query, this query finds the various "types" of memory objects
--that have been allocated via those Memory Clerks. This could potentially come in handy if a particular memory clerk
--had a lot of allocated memory (most likely either the SPA or the MPA, though I supposed the VM and SM interfaces are also possible)
--and we wanted to see what types of objects were being allocated.
--For example, at UCLA-TRAC, when we were seeing exhaustion of the MemToLeave area when leaving the -g value at the default, using
--the above query helped to identify the MEMORYCLERK_SOSNODE clerk as a major consumer, and using this query helped us to see that
--objects of type MEMOBJ_SOSWORKER were a significant part of this memory usage.
--The value of this query can be overstated, however. There are a couple of important caveats:
--  1. Many of the entries in sys.dm_os_memory_objects have a page_allocator_address that does NOT map to a memory clerk
--      At this point, I don't know why that is. (Still researching) Most (all?) of these entries are related to query compilation/caching,
--      which makes me suspect that they are "stolen" from the buffer pool rather than "allocated" from the buffer pool via a memory clerk
--     We must also remember that external components that aren't tracked by a memory clerk (e.g. sp_OACreate objects and XPs) won't appear
--      in either the Clerks DMV or the Mem Objects DMV.
--     When we combine these 2 facts, the definitiveness of this query in determining MemToLeave exhaustion/fragmention or Data-Cache BP ineffectiveness
--      is somewhat subdued
--  2. Knowing what Object Types are using a lot of memory is different than being able to do something about their usage. For some of the Clerk/Object
--      names that are more obscure (MEMORKCLERK_SQLSTORENG/MEMOBJ_SORTTABLE) or core to the system (MEMORYCLERK_SOSNODE/MEMOBJ_SOSSCHEDULER),
--      even if we are able to determine precisely what parts of SQL use the memory represented by this query for a given entry, we may not be able
--      or desire to limit its usage.
select ss2.ClerkAddress, ss2.ClerkType, Clerkname, ObjectType, ObjectCount, TotalPagesAllocated, convert(bigint,TotalBytes/1024.0) as Total_KB, 
	mcl2.memory_node_Id as MemNode, mcl2.single_pages_kb as SPA_kb, mcl2.multi_pages_kb as MPA_kb, mcl2.virtual_memory_reserved_kb as VMReserved_kb,
	mcl2.virtual_memory_committed_kb as VMCommitted_kb, mcl2.awe_allocated_kb as AWE_kb, mcl2.shared_memory_reserved_kb as SMReserved_kb, 
	mcl2.shared_memory_committed_kb as SMCommitted_kb
from 
(select ClerkAddress, ClerkType, ClerkName, ObjectType, count(*) as ObjectCount, sum( pages_allocated_count ) as TotalPagesAllocated, sum(ObjectBytes) as TotalBytes
from (select mcl.memory_clerk_address as ClerkAddress, mcl.[type] as ClerkType, mcl.[name] as ClerkName, mob.[type] as ObjectType, 
	mob.pages_allocated_count, ((mob.pages_allocated_count*1.0)*(page_size_in_bytes*1.0)) as ObjectBytes
		from sys.dm_os_memory_clerks mcl
			inner join sys.dm_os_memory_objects mob
				on mcl.page_allocator_address = mob.page_allocator_address
		where mcl.memory_clerk_address in (select memory_clerk_address
											from sys.dm_os_memory_clerks mc
											where (single_pages_kb+multi_pages_kb+virtual_memory_reserved_kb+shared_memory_reserved_kb) 
													> 128) 
		) ss
group by ClerkAddress, ClerkType, ClerkName, ObjectType) ss2
	inner join sys.dm_os_memory_clerks mcl2
		on ss2.ClerkAddress = mcl2.memory_clerk_address
order by ClerkType, ClerkName, ClerkAddress, ObjectCount Desc



--Memory usage by Memory Objects for those MOBs that can be tied to a Memory Clerk
select 'Memory Objects WITH Memory Clerk', sum(numPages) as TotalPages, convert(bigint,sum(ObjectBytes)/1024.) as TotalKB
from
(select mcl.memory_clerk_address as ClerkAddress, mcl.[type] as ClerkType, mcl.[name] as ClerkName, mob.[type] as ObjectType, 
	mob.pages_allocated_count as NumPages, ((mob.pages_allocated_count*1.0)*(page_size_in_bytes*1.0)) as ObjectBytes
		from sys.dm_os_memory_clerks mcl
			inner join sys.dm_os_memory_objects mob
				on mcl.page_allocator_address = mob.page_allocator_address) ss
union 
--Memory usage by Memory Objects that can't be tied to a Memory Clerk
select 'Memory Objects without a Memory Clerk', sum(numPages) as TotalPages, convert(bigint,sum(ObjectBytes)/1024.) as TotalKB
from
(select mcl.memory_clerk_address as ClerkAddress, mcl.[type] as ClerkType, mcl.[name] as ClerkName, mob.[type] as ObjectType, 
	mob.pages_allocated_count as NumPages, page_size_in_bytes, ((mob.pages_allocated_count*1.0)*(page_size_in_bytes*1.0)) as ObjectBytes
		from sys.dm_os_memory_clerks mcl
			right outer join sys.dm_os_memory_objects mob
				on mcl.page_allocator_address = mob.page_allocator_address
		where mcl.page_allocator_address is null) ss

