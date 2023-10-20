CREATE EVENT SESSION [SS_PRE_MATRICULA] ON SERVER 
ADD EVENT sqlserver.sp_statement_completed(
    ACTION(sqlserver.query_hash,sqlserver.sql_text)
    WHERE ([sqlserver].[session_id]=(56))),
ADD EVENT sqlserver.sql_statement_completed(
    ACTION(sqlserver.query_hash,sqlserver.sql_text)
    WHERE ([sqlserver].[session_id]=(56)))
ADD TARGET package0.event_file(SET filename=N'C:\local_arquivo\arquivo*.xel',max_file_size=(30720))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO
------------------------------AT�  AQUI CRIA O EVENTO




-- copy event data into temp table #Events
SELECT CAST(event_data AS XML) AS event_data_XML
INTO #Events
FROM sys.fn_xe_file_target_read_file('C:\local_arquivo\arquivo*.xel', null, null, null) AS F;

-- extract query perf info temp table #Queries
SELECT
  event_data_XML.value ('(/event/action[@name=''query_hash''    ]/value)[1]', 'BINARY(8)'     ) AS query_hash,
  event_data_XML.value ('(/event/data  [@name=''duration''      ]/value)[1]', 'BIGINT'        ) AS duration,
  event_data_XML.value ('(/event/data  [@name=''cpu_time''      ]/value)[1]', 'BIGINT'        ) AS cpu_time,
  event_data_XML.value ('(/event/data  [@name=''physical_reads'']/value)[1]', 'BIGINT'        ) AS physical_reads,
  event_data_XML.value ('(/event/data  [@name=''logical_reads'' ]/value)[1]', 'BIGINT'        ) AS logical_reads,
  event_data_XML.value ('(/event/data  [@name=''writes''        ]/value)[1]', 'BIGINT'        ) AS writes,
  event_data_XML.value ('(/event/data  [@name=''row_count''     ]/value)[1]', 'BIGINT'        ) AS row_count,
  event_data_XML.value ('(/event/data  [@name=''statement''     ]/value)[1]', 'NVARCHAR(4000)') AS statement
INTO #Queries
FROM #Events;

--CREATE CLUSTERED INDEX idx_cl_query_hash ON #Queries(query_hash);
-- examine query info
SELECT * FROM #Queries;

DROP TABLE #Events;
DROP TABLE #Queries;



/****** Script for SelectTopNRows command from SSMS  ******/
SELECT [query_hash]
      ,[duration]
      ,[cpu_time]
      ,[physical_reads]
      ,[logical_reads]
      ,[writes]
      ,[row_count]
      ,[statement]
  FROM [Aux_Temp].[dbo].[testeanalisematricula] a
  where a.duration > 1000

  SELECT query_hash,
  COUNT(*) AS num_queries,
  SUM(logical_reads) AS sum_logical_reads,
  CAST(100.0 * SUM(logical_reads)
             / SUM(SUM(logical_reads)) OVER() AS NUMERIC(5, 2)) AS pct,
  CAST(100.0 * SUM(SUM(logical_reads)) OVER(ORDER BY SUM(logical_reads) DESC
                                            ROWS UNBOUNDED PRECEDING)
             / SUM(SUM(logical_reads)) OVER()
       AS NUMERIC(5, 2)) AS running_pct
FROM [Aux_Temp].[dbo].[testeanalisematricula]
GROUP BY query_hash
ORDER BY sum_logical_reads DESC;


-- simplified
WITH QueryHashTotals AS
(
  SELECT query_hash,
    COUNT(*) AS num_queries,
    SUM(logical_reads) AS sum_logical_reads
  FROM [Aux_Temp].[dbo].[testeanalisematricula]
  GROUP BY query_hash
)
SELECT query_hash, num_queries, sum_logical_reads,
  CAST(100. * sum_logical_reads
            / SUM(sum_logical_reads) OVER()
       AS NUMERIC(5, 2)) AS pct,
  CAST(100. * SUM(sum_logical_reads) OVER(ORDER BY sum_logical_reads DESC
                                          ROWS UNBOUNDED PRECEDING)
            / SUM(sum_logical_reads) OVER()
       AS NUMERIC(5, 2)) AS running_pct
FROM QueryHashTotals
ORDER BY sum_logical_reads DESC;


-- filter and include a sample query
WITH QueryHashTotals AS
(
  SELECT query_hash,
    COUNT(*) AS num_queries,
    SUM(logical_reads) AS sum_logical_reads
  FROM  [Aux_Temp].[dbo].[testeanalisematricula]
  GROUP BY query_hash
),
RunningTotals AS
(
  SELECT query_hash, num_queries, sum_logical_reads,
    CAST(100. * sum_logical_reads
              / SUM(sum_logical_reads) OVER()
         AS NUMERIC(5, 2)) AS pct,
    CAST(100. * SUM(sum_logical_reads) OVER(ORDER BY sum_logical_reads DESC
                                             ROWS UNBOUNDED PRECEDING)
              / SUM(sum_logical_reads) OVER()
         AS NUMERIC(5, 2)) AS running_pct
  FROM QueryHashTotals
)
SELECT RT.*, (SELECT TOP (1) statement
              FROM  [Aux_Temp].[dbo].[testeanalisematricula] AS Q
              WHERE Q.query_hash = RT.query_hash) AS sample_statement
FROM RunningTotals AS RT
WHERE running_pct - pct < 80.00
ORDER BY sum_logical_reads DESC;


WITH RunningTotals AS
(
  SELECT
    query_hash,
    SUM(execution_count) AS num_queries,
    SUM(total_logical_reads) AS sum_logical_reads,
    CAST(100. * SUM(total_logical_reads)
              / SUM(SUM(total_logical_reads)) OVER()
          AS NUMERIC(5, 2)) AS pct,
    CAST(100. * SUM(SUM(total_logical_reads)) OVER(ORDER BY SUM(total_logical_reads) DESC
                                              ROWS UNBOUNDED PRECEDING)
              / SUM(SUM(total_logical_reads)) OVER()
          AS NUMERIC(5, 2)) AS running_pct
  FROM sys.dm_exec_query_stats AS QS
    CROSS APPLY sys.dm_exec_query_plan(QS.plan_handle) AS QP
  WHERE QS.query_hash <> 0x
    AND QP.dbid = DB_ID('Performance')
  GROUP BY query_hash
)
SELECT RT.*,
  (SELECT TOP (1)
     SUBSTRING(ST.text, (QS.statement_start_offset/2) + 1,
             ((CASE statement_end_offset
                WHEN -1 THEN DATALENGTH(ST.text)
                ELSE QS.statement_end_offset END
                    - QS.statement_start_offset)/2) + 1
           )
   FROM sys.dm_exec_query_stats AS QS
     CROSS APPLY sys.dm_exec_sql_text(QS.sql_handle) AS ST
   WHERE QS.query_hash = RT.query_hash) AS sample_statement
FROM RunningTotals AS RT
WHERE running_pct - pct < 80.00
ORDER BY sum_logical_reads DESC;