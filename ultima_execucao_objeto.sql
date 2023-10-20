select *
  from sys.objects a
 where a.name = 'NOME_OBJETO';

 SELECT	object_name(m.object_id) AS Nome_Procedure,
		MAX(qs.last_execution_time) AS Ultima_Execucao
FROM	sys.sql_modules m
		LEFT   JOIN (sys.dm_exec_query_stats qs
               CROSS APPLY sys.dm_exec_sql_text (qs.sql_handle) st)
         ON m.object_id = st.objectid
        AND st.dbid = db_id()
WHERE object_name(m.object_id) = 'NOME_OBJETO'
GROUP  BY object_name(m.object_id);