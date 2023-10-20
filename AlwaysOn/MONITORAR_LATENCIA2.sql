WHILE 1=1
BEGIN
  SELECT drcs.database_name, ars.role_desc, drs.log_send_queue_size, drs.log_send_rate,
ars.recovery_health_desc, ars.connected_state_desc, ars.operational_state_desc, ars.synchronization_health_desc, *
  FROM sys.dm_hadr_availability_replica_states ars JOIN sys.dm_hadr_database_replica_cluster_states drcs ON ars.replica_id=drcs.replica_id
  JOIN sys.dm_hadr_database_replica_states drs ON drcs.group_database_id=drs.group_database_id
  WHERE ars.role_desc='SECONDARY' AND drs.is_local=0 and drs.log_send_queue_size > 0
  waitfor delay '00:00:30'
END