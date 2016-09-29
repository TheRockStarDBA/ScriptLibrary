declare @request_session_id int = null,
	@ignore_granted char(1) = 'Y';		--null for all spids; no, you shouldn't write code this way in an actual app.

SELECT request_session_id, ec,
	resource_type, resource_subtype, resource_description, request_mode,
	associatedEntity, resourceDB, request_type,
	request_status, request_reference_count, 
	request_lifetime, request_owner_type, 
	request_owner_id, request_owner_guid, 
	request_owner_lockspace_id, lock_owner_address,	ordernum
FROM 
(select request_session_id, request_exec_context_id as ec,
	resource_type, resource_subtype, 
	DB_NAME(resource_database_id) as resourceDB, 
	case when resource_type = 'DATABASE' THEN DB_NAME(resource_database_id)
		when resource_type = 'OBJECT' THEN OBJECT_NAME(resource_associated_entity_id) 
		WHEN resource_type = 'KEY' THEN (SELECT OBJECT_NAME(object_id) + ': partition: ' + CONVERT(varchar(30), partition_id )
										FROM sys.partitions WHERE partition_id = resource_associated_entity_id)
		WHEN resource_type = 'PAGE' THEN (SELECT OBJECT_NAME(object_id) + ': partition: ' + CONVERT(varchar(30), partition_id )
										FROM sys.partitions WHERE partition_id = resource_associated_entity_id)
		
		when resource_type IN ('RID') THEN CONVERT(varchar(40), resource_associated_entity_id)
		else CONVERT(varchar(40), resource_associated_entity_id) end as associatedEntity,
	resource_description,
	request_mode, 
	request_type,
	request_status, 
	request_reference_count, 
	request_lifetime, 
	request_owner_type, 
	request_owner_id, 
	request_owner_guid, 
	request_owner_lockspace_id, 
	lock_owner_address,
	case when resource_type = 'DATABASE' THEN 1
		when resource_type = 'OBJECT' THEN 2
		when resource_type IN ('KEY','PAGE','RID') THEN 3
		else 4 end as ordernum
from sys.dm_tran_locks 
where (request_session_id = @request_session_id 
	or @request_session_id IS NULL
	)
and (
	1 = case when @ignore_granted = 'Y'
		request_status = 'GRANT' THEN 0
		ELSE 1 END
  )
) SS
order by ordernum asc,  associatedEntity, resource_description

