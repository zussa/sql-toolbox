set transaction isolation level read uncommitted

use master;

SELECT --r.*, 
    --rsql.text as [sql],
    s.session_id,
	Cast(((Datediff(s, start_time, Getdate()))/3600) AS VARCHAR)  + ' hour(s), '
				   + Cast((Datediff(s, start_time, Getdate())%3600)/60 AS VARCHAR) + 'min, ' 
				   + Cast((Datediff(s, start_time, Getdate())%60) AS VARCHAR)      + ' sec' AS running_time,
    'Kill ' + convert(varchar(222),s.session_id),
    r.blocking_session_id as 'kill_s',

    r.reads, r.writes, r.logical_reads, r.cpu_time,
	db_name(r.database_id) as database_name,
	s.login_name,
    s.host_name,
	s.original_login_name,
	SUBSTRING(rsql.text,(r.statement_start_offset/2)+1,
		CASE WHEN statement_end_offset=-1 OR statement_end_offset=0 
            THEN (DATALENGTH(rsql.Text)-r.statement_start_offset/2)+1 
            ELSE (r.statement_end_offset-r.statement_start_offset)/2+1
    END) [Individual Query], 
	rsql.text as [sql],
    s.program_name,
	j.name as job_name,
    r.percent_complete,
	c.client_net_address,
    
    --r.request_id,
    r.command,
    r.status,
    r.last_wait_type,
	r.wait_type,
	r.wait_time,
	r.wait_resource,
	OBJECT_NAME(rsql.objectid) AS object_name,
	s.login_time,
	r.start_time,
    --((r.total_elapsed_time/1000)/60) AS [total_elapsed_time (r-min)],
    --r.database_id,
	
	GETDATE(),	
	rplan.query_plan
  FROM
               sys.dm_exec_sessions    as s
    INNER JOIN sys.dm_exec_connections as c ON s.session_id = c.session_id
    INNER JOIN sys.dm_exec_requests    as r ON s.session_id = r.session_id
	LEFT  JOIN msdb.dbo.sysjobs		   as j ON s.program_name like '%'+cast(right(j.job_id,12)as varchar(12)) +'%'
    
    outer APPLY sys.dm_exec_sql_text(r.sql_handle) as rsql
	OUTER APPLY sys.dm_exec_query_plan(r.plan_handle) AS rplan


  WHERE
    s.session_id  > 50 AND
    s.session_id <> @@spid 
	and s.is_user_process = 1
and s.program_name not like 'DatabaseMail - DatabaseMail%'
 ORDER BY 27  , r.cpu_time desc, r.logical_reads desc, s.session_id--, desc, r.command, s.program_name, r.blocking_session_id, s.session_id

 
