
SELECT CASE ar.replica_server_name
           WHEN 'SERVER15\INSTANCE'
           THEN 'Primary Replica'
           WHEN 'SERVER16\INSTANCE'
           THEN 'Secondary DC Replica'
		   WHEN 'SERVER17\INSTANCE'
           THEN 'Secondary DC Replica'
           ELSE 'Secondary DR Replica'
       END AS Replica, 
	   ar.replica_server_name,
       adc.database_name, 
       drs.is_local, 
       drs.is_primary_replica, 
       drs.synchronization_state_desc, 
       drs.is_commit_participant, 
       drs.synchronization_health_desc, 
       drs.recovery_lsn
FROM sys.dm_hadr_database_replica_states AS drs
     INNER JOIN sys.availability_databases_cluster AS adc ON drs.group_id = adc.group_id
     AND drs.group_database_id = adc.group_database_id
     INNER JOIN sys.availability_groups AS ag ON ag.group_id = drs.group_id
     INNER JOIN sys.availability_replicas AS ar ON drs.group_id = ar.group_id
     AND drs.replica_id = ar.replica_id
ORDER BY Replica;

SELECT CASE r.replica_server_name
           WHEN 'SERVER15\INSTANCE'
           THEN 'Primary Replica'
           WHEN 'SERVER16\INSTANCE'
           THEN 'Secondary DC Replica'
		   WHEN 'SERVER17\INSTANCE'
           THEN 'Secondary DC Replica'
           ELSE 'Secondary DR Replica'
       END AS Replica, 
	   r.replica_server_name,
	    adc.database_name, 
       rs.is_primary_replica IsPrimary, 
       rs.last_received_lsn, 
       rs.last_hardened_lsn, 
       rs.last_redone_lsn, 
       rs.end_of_log_lsn, 
       rs.last_commit_lsn
FROM sys.availability_replicas r
     INNER JOIN sys.dm_hadr_database_replica_states rs ON r.replica_id = rs.replica_id
	 INNER JOIN sys.availability_databases_cluster AS adc ON RS.group_id = adc.group_id
     AND RS.group_database_id = adc.group_database_id
	 --where  adc.database_name in ('STUDEO' )
ORDER BY 3, 1;
