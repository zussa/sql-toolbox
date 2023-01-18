--sp_readerrorlog 0
--sp_cycle_errorlog
--Kill 197
--dbcc inputbuffer(430)
--dbcc inputbuffer(3307)
--select * from Lyceum.dbo.LY_USUARIO_SESSAO where SESSAO_ID = 3459	
--select * from rh.sys.tables WHERE NAME > 'R067DEM' order by NAME
--SELECT * FROM msdb.dbo.sysjobs where job_id = '958CF6195EE5D54BBC656DDF5266F7F9'
--SELECT * FROM msdb.dbo.sysjobhistory where run_date = '20130617' order by run_time
--SELECT sqlserver_start_time as  [SQL Server Instance Uptime] from sys.dm_os_sys_info
--DBCC OPENTRAN()
-- sp_who2  3307   
-- sp_who3
-- sp_whoisactive @sort_order = '[tempdb_allocations] DESC', @show_sleeping_spids = 2, @find_block_leaders=1
-- sp_whoisactive @get_additional_info =1, @get_plans =1, @show_sleeping_spids = 0, @find_block_leaders=1  --, @filter_type = 'login', @filter = 'valorizza'
--select * from sysprocesses where spid <> @@SPID AND SPID= 1661 AND CPU > 1000 order by cpu desc
--select count(1) from dw.[rhu].[DIM_EVENTO_FOLHA] 
-- Busca informações da sessão que esta bloqueada

--select * from sys.dm_exec_sessions where session_id= 1661 --program_name = 'PHP 5' and host_name = 'srv-web2.ead.cesumar.br'
--select * from sys.dm_exec_requests where session_id = 1661
--select * from sys.dm_exec_connections where session_id = 1661
--select * from sys.dm_exec_connections a  cross apply sys.dm_exec_sql_text(a.most_recent_sql_handle) x where session_id = 1971


--sys.dm_exec_requests - status
--•Background - reserved for internal background requests. These will always have session identifier less than or equal to 50.
--•Running    - the request is currently being executed.
--•Runnable   - the request is placed in runnable queue. Resources are available but request is waiting for an available scheduler.
--•Sleeping   - connection is open but either no SQL statement has been submitted or the submitted statements have been executed. SQL Server is waiting for the next request from this connection. 
--•Suspended  - request is waiting on resource (is in the waiting queue)

--select rsql.text, *,
--    ( SELECT USUARIO
--        FROM Lyceum.dbo.LY_USUARIO_SESSAO
--       WHERE
--          sessao_id      = r.session_id
--    ) as [current_user_lyceum]
--  from sys.dm_exec_connections r
--    OUTER APPLY sys.dm_exec_sql_text(r.most_recent_sql_handle) as rsql
-- where
--    session_id = 321

--sp_helptext DESATIVA_DOCENTE_LYCEUM
--select count(1) from lyceum.dbo.CES_TB_INGRESSO_EAD where DH_INSERT >= '2021-09-02 00:00:00.000' and aluno is null
--cpu_time
--memory_usage
--total_scheduled_time
    
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
	--iif( kh.NM_GRUPO is null , s.host_name, concat(kh.NM_GRUPO,' - (',kh.NM_HOST,')')) as [host_name] ,
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
	
    --( SELECT USUARIO
    --    FROM Lyceum.dbo.LY_USUARIO_SESSAO
    --   WHERE
    --      sessao_id      = s.session_id --and 
    ----      s.program_name in ('GeraCalcMatr','Enturmação','GeraPreMatricula','Lyceum','GeraBoleto','ImportaArquivo','RemoveCobranca','GeraCobrancaItens','GeraPreMatricula','RemoveBoleto')
    --) as [current_user_lyceum],

    

    --( SELECT USUARIO
    --    FROM Lyceum.dbo.LY_USUARIO_SESSAO
    --   WHERE
    --      sessao_id      = r.blocking_session_id-- and
    --     -- s.program_name in ('EfetivaPreMatricula','Lyceum','GeraBoleto','ImportaArquivo','GeraCobrancaItens','RemoveBoleto')
    --) as [blocking_user_lyceum],
	rplan.query_plan
  FROM
               sys.dm_exec_sessions    as s
    INNER JOIN sys.dm_exec_connections as c ON s.session_id = c.session_id
    INNER JOIN sys.dm_exec_requests    as r ON s.session_id = r.session_id
	LEFT  JOIN msdb.dbo.sysjobs		   as j ON s.program_name like '%'+cast(right(j.job_id,12)as varchar(12)) +'%'
    
    outer APPLY sys.dm_exec_sql_text(r.sql_handle) as rsql
	OUTER APPLY sys.dm_exec_query_plan(r.plan_handle) AS rplan

	--LEFT JOIN master.dbo.KNOW_HOST kh on kh.NM_HOST = s.host_name and kh.DH_DELETE is null


  WHERE
    --j.name = 'CONT Coleta Argyros' and
    s.session_id  > 50 AND
    s.session_id <> @@spid 
	and s.is_user_process = 1
	--and s.program_name ='ImportaArquivo' 
	/*and
	--s.program_name ='Fechamento do Período Letivo' and
	s.program_name not in ('SQLAgent - TSQL JobStep (Job 0x2C8157FCFA3AB045A2BEC88DFC86CF27 : Step 2)',
'SQLAgent - TSQL JobStep (Job 0xFBA9947DA4426847A6558B2AC9B25650 : Step 2)',
'SQLAgent - TSQL JobStep (Job 0x3F35B9DE9D7BB343A14F2A6A6FAA18BC : Step 2)',
'SQLAgent - TSQL JobStep (Job 0xCC0F63C6C2B6A640B5E0E19A181357D0 : Step 2)',
'SQLAgent - TSQL JobStep (Job 0x9F0872751068D24B8438F0B0369488F3 : Step 2)',
'SQLAgent - TSQL JobStep (Job 0x89439CED7AD4074E87C3E947921F0245 : Step 2)',
'SQLAgent - TSQL JobStep (Job 0xA294BC8C0F9F274385520BC1E0DC3C08 : Step 2)',
'SQLAgent - TSQL JobStep (Job 0x8FC6AE10BE456A439DD3493EC5E04103 : Step 2)'
)*/
and s.program_name not like 'DatabaseMail - DatabaseMail%'
--and s.program_name ='Fechamento do Período Letivo'
--and rsql.text <> 'sp_server_diagnostics'
--AND rsql.text not like '%[sys].[sp_cdc_scan]%'
--AND S.original_login_name NOT IN ('usr_retorno_bancario','valorizza','ls_universoead','ADM-CESUMAR\user.hp')
 ORDER BY 27  , r.cpu_time desc, r.logical_reads desc, s.session_id--, desc, r.command, s.program_name, r.blocking_session_id, s.session_id

 
--select * from sys.dm_io_pending_io_requests
--select * from lyceum.dbo.LY_PROC_ANDAMENTO order by time_ini desc
--select * from lyceum.dbo.LY_PROC_ANDAMENTO WITH (ROWLOCK) WHERE id_proc = 341
--select msg from lyceum.dbo.LY_PROC_ANDAMENTO_log WITH (ROWLOCK) WHERE id_proc = 341
--Kill 169
/*

select * from lyceum.dbo.LY_PROC_ANDAMENTO a WITH (ROWLOCK)
join lyceum.dbo.ly_usuario_sessao b on b.SESSAO_ID = a.ID_PROC
 --WHERE id_proc in (select sessao_id from ) 
where b.USUARIO ='ligia'


select * from lyceum.dbo.LY_PROC_ANDAMENTO a WITH (ROWLOCK)
join lyceum.dbo.ly_usuario_sessao b on b.SESSAO_ID = a.ID_PROC
 --WHERE id_proc in (select sessao_id from ) 
where b.USUARIO ='ligia'
*/
--select * from Lyceum.dbo.ly_usuario_sessao where SESSAO_ID = 296
/*
select * from Hades.dbo.HD_AUDIT_EVENTO where DATA >= '2021-12-20' and data < '2021-12-21' and USUARIO ='jaqueline.lima'	 and origem = 'FechaPerLtv' order by evento desc
select * from Hades.dbo.HD_AUDIT_EVENTO where DATA >= '2021-12-20' and data < '2021-12-21' and USUARIO ='aline.dutra'	 and origem = 'FechaPerLtv' order by evento desc
select * from Hades.dbo.HD_AUDIT_EVENTO where DATA >= '2021-12-20' and data < '2021-12-21' and origem = 'FechaPerLtv' order by evento desc
select * from Hades.dbo.HD_AUDIT_EVENTO where DATA >= '2021-12-21' and origem = 'CES_BOL_003' order by evento desc

select * from Hades.dbo.HD_AUDIT_EVENTO_DETALHE where EVENTo = 644449
select * from Hades.dbo.HD_AUDIT_EVENTO_PARAMETRO where EVENTo = 644449

select * from Hades.dbo.HD_AUDIT_EVENTO_DETALHE where EVENTo = 644455
select * from Hades.dbo.HD_AUDIT_EVENTO_PARAMETRO where EVENTo = 644455

select * from Hades.dbo.HD_AUDIT_EVENTO_DETALHE where EVENTo = 644463
select * from Hades.dbo.HD_AUDIT_EVENTO_PARAMETRO where EVENTo = 644463

select * from Hades.dbo.HD_AUDIT_EVENTO_DETALHE where EVENTo = 644476
select * from Hades.dbo.HD_AUDIT_EVENTO_PARAMETRO where EVENTo = 644476
*/

