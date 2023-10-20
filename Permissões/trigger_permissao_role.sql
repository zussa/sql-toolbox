CREATE TRIGGER ApplyPermissionsToAllProceduressAndFunctions -- be more creative!
    ON DATABASE FOR CREATE_PROCEDURE, CREATE_FUNCTION, CREATE_VIEW
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @sql       NVARCHAR(MAX),
        @EventData XML = EVENTDATA();

    ;WITH x ( sch, obj ) 
    AS
    (
        SELECT
          @EventData.value('(/EVENT_INSTANCE/SchemaName)[1]',  'NVARCHAR(255)'), 
          @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]',  'NVARCHAR(255)')
    )
    SELECT @sql = N'GRANT ' + CASE 
      WHEN o.type_desc LIKE 'SQL_%TABLE_VALUED_FUNCTION' 
        OR o.type_desc = 'VIEW'
      THEN ' SELECT ' 
      ELSE ' EXEC ' END 
        + ' ON ' + QUOTENAME(x.sch) 
        + '.' + QUOTENAME(x.obj) 
        + ' TO testuser;' -- hard-code this, use a variable, or store in a table
    FROM x
    INNER JOIN sys.objects AS o
    ON o.[object_id] = OBJECT_ID(QUOTENAME(x.sch) + '.' + QUOTENAME(x.obj));

    EXEC sp_executesql @sql;
END
GO