select node_id,
	   physical_operator_name,
	   sum(row_count) as row_count,
	   sum(estimate_row_count) as estimate_row_count,
	   cast(sum(row_count)*100 as float) / sum(estimate_row_count) as percent_complete
  from sys.dm_exec_query_profiles
  where session_id = 1480
   group by node_id,
            physical_operator_name
	order by node_id
