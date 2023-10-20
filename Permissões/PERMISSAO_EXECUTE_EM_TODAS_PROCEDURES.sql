declare @sqlStmt   varchar(max)		
declare @tb_script table ( script varchar(max) )

insert into @tb_script
SELECT   'use DB' + CHAR(13) + CHAR(10) + 		
		'GRANT EXECUTE ON ' +  a.specific_schema +'.'+ a.specific_name + ' TO [user] ' + CHAR(13) + CHAR(10) 		
  from lyceum.information_schema.routines a
 where routine_type = 'PROCEDURE' 
   and Left(Routine_Name, 3) NOT IN ('sp_', 'xp_', 'ms_');

DECLARE cur_script CURSOR FOR 
  SELECT script 
    FROM @tb_script; 

OPEN cur_script; 

FETCH next FROM cur_script INTO @sqlStmt; 

WHILE @@FETCH_STATUS = 0 
  BEGIN; 
    PRINT @sqlStmt;
	--EXEC (@sqlStmt); 
      FETCH next FROM cur_script INTO @sqlStmt; 
  END; 
CLOSE cur_script; 

DEALLOCATE cur_script; 

go
