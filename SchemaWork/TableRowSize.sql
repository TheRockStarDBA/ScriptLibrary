--Taken from http://support.microsoft.com/kb/2986423

select 
 1+1+2 + 2 + 
	(case  
		when sum (case when leaf_offset < 0 then 1 else 0 end) > 0 
		then 2 
		else 0 
	  end)  + 
	( 
		(count (*) + 7)/8 
	) + 
		count (case when leaf_offset < 0 then 1 else null end) * 2 + 
		sum( case when max_length=-1 then 24 else max_length end) 
 from sys.system_internals_partition_columns col 
	join sys.partitions par 
		on col.partition_id = par.partition_id 
 where object_id = object_id ('<table name>')  and  index_id in (0,1) and partition_number =1
