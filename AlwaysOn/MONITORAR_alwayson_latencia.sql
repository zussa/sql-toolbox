--Check metrics first
 
IF OBJECT_ID('tempdb..#perf') IS NOT NULL
	DROP TABLE #perf
 
SELECT IDENTITY (int, 1,1) id
	,instance_name
	,CAST(cntr_value * 1000 AS DECIMAL(19,2)) [mirrorWriteTrnsMS]
	,CAST(NULL AS DECIMAL(19,2)) [trnDelayMS]
INTO #perf
FROM sys.dm_os_performance_counters perf
WHERE perf.counter_name LIKE 'Mirrored Write Transactions/sec%'
	AND object_name LIKE 'SQLServer:Database Replica%'
	
UPDATE p
SET p.[trnDelayMS] = perf.cntr_value
FROM #perf p
INNER JOIN sys.dm_os_performance_counters perf ON p.instance_name = perf.instance_name
WHERE perf.counter_name LIKE 'Transaction Delay%'
	AND object_name LIKE 'SQLServer:Database Replica%'
	AND trnDelayMS IS NULL
 
-- Wait for recheck
-- I found that these performance counters do not update frequently,
-- thus the long delay between checks.
WAITFOR DELAY '00:05:00'
GO
--Check metrics again
 
INSERT INTO #perf
(
	instance_name
	,mirrorWriteTrnsMS
	,trnDelayMS
)
SELECT instance_name
	,CAST(cntr_value * 1000 AS DECIMAL(19,2)) [mirrorWriteTrnsMS]
	,NULL
FROM sys.dm_os_performance_counters perf
WHERE perf.counter_name LIKE 'Mirrored Write Transactions/sec%'
	AND object_name LIKE 'SQLServer:Database Replica%'
	
UPDATE p
SET p.[trnDelayMS] = perf.cntr_value
FROM #perf p
INNER JOIN sys.dm_os_performance_counters perf ON p.instance_name = perf.instance_name
WHERE perf.counter_name LIKE 'Transaction Delay%'
	AND object_name LIKE 'SQLServer:Database Replica%'
	AND trnDelayMS IS NULL
	
--Aggregate and present
 
;WITH AG_Stats AS 
			(
			SELECT AR.replica_server_name,
				   HARS.role_desc, 
				   Db_name(DRS.database_id) [DBName]
			FROM   sys.dm_hadr_database_replica_states DRS 
			INNER JOIN sys.availability_replicas AR ON DRS.replica_id = AR.replica_id 
			INNER JOIN sys.dm_hadr_availability_replica_states HARS ON AR.group_id = HARS.group_id 
				AND AR.replica_id = HARS.replica_id 
			),
	Check1 AS
			(
			SELECT DISTINCT p1.instance_name
				,p1.mirrorWriteTrnsMS
				,p1.trnDelayMS
			FROM #perf p1
			INNER JOIN 
				(
					SELECT instance_name, MIN(id) minId
					FROM #perf p2
					GROUP BY instance_name
				) p2 ON p1.instance_name = p2.instance_name
			),
	Check2 AS
			(
			SELECT DISTINCT p1.instance_name
				,p1.mirrorWriteTrnsMS
				,p1.trnDelayMS
			FROM #perf p1
			INNER JOIN 
				(
					SELECT instance_name, MAX(id) minId
					FROM #perf p2
					GROUP BY instance_name
				) p2 ON p1.instance_name = p2.instance_name
			),
	AggregatedChecks AS
			(
				SELECT DISTINCT c1.instance_name
					, c2.mirrorWriteTrnsMS - c1.mirrorWriteTrnsMS mirrorWriteTrnsMS
					, c2.trnDelayMS - c1.trnDelayMS trnDelayMS
				FROM Check1 c1
				INNER JOIN Check2 c2 ON c1.instance_name = c2.instance_name
			),
	Pri_CommitTime AS 
			(
			SELECT	replica_server_name
					, DBName
			FROM	AG_Stats
			WHERE	role_desc = 'PRIMARY'
			),
	Sec_CommitTime AS 
			(
			SELECT	replica_server_name
					, DBName
			FROM	AG_Stats
			WHERE	role_desc = 'SECONDARY'
			)
SELECT p.replica_server_name [primary_replica]
	, p.[DBName] AS [DatabaseName]
	, s.replica_server_name [secondary_replica]
	, CAST( CASE WHEN ac.trnDelayMS = 0 THEN 1 ELSE ac.trnDelayMS END AS DECIMAL(19,2) ) / (ac.mirrorWriteTrnsMS) sync_lag_MS
FROM Pri_CommitTime p
LEFT JOIN Sec_CommitTime s ON [s].[DBName] = [p].[DBName]
LEFT JOIN AggregatedChecks ac ON ac.instance_name = p.DBName