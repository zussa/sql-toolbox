DECLARE 
    @sql      NVARCHAR(MAX) = N'',
    @username VARCHAR(255)  = 'testuser';

SELECT @sql += CHAR(13) + CHAR(10) + N'GRANT ' + CASE 
    WHEN type_desc LIKE 'SQL_%TABLE_VALUED_FUNCTION'
      OR type_desc = 'VIEW'
    THEN ' SELECT ' ELSE ' EXEC ' END 
    + ' ON ' + QUOTENAME(SCHEMA_NAME([schema_id])) 
    + '.' + QUOTENAME(name) 
    + ' TO ' + @username + ';'
 FROM sys.all_objects
WHERE is_ms_shipped = 0 AND
( 
    type_desc LIKE '%PROCEDURE' 
    OR type_desc LIKE '%FUNCTION'
    OR type_desc = 'VIEW'
);

PRINT @sql;
-- EXEC sp_executesql @sql;