SET NOCOUNT ON

CREATE TABLE #DatabaseRoleMemberShip 
   (
        Username VARCHAR(100),
        Rolename VARCHAR(100),
        Databasename VARCHAR(100)
         
    )DECLARE @Cmd AS VARCHAR(MAX)DECLARE @PivotColumnHeaders VARCHAR(4000)           SET @Cmd = 'USE [?] ;insert into #DatabaseRoleMemberShip 
select u.name,r.name,''?'' from sys.database_role_members rm inner join 
sys.database_principals U on U.principal_id=rm.member_principal_id
inner join sys.database_principals R on R.principal_id=rm.role_principal_id
where u.type<>''R'''EXEC sp_MSforeachdb @command1=@cmd

SELECT  @PivotColumnHeaders =                         
  COALESCE(@PivotColumnHeaders + ',[' + CAST(rolename AS VARCHAR(MAX)) + ']','[' + CAST(rolename AS VARCHAR(MAX))+ ']'                     
  )                     
  FROM (SELECT DISTINCT rolename FROM #DatabaseRoleMemberShip )a ORDER BY rolename  ASC


SET @Cmd = 'select 
databasename,username,'+@PivotColumnHeaders+'
from 
(
select   * from #DatabaseRoleMemberShip) as p
pivot 
(
count(rolename  )
for rolename in ('+@PivotColumnHeaders+') )as pvt'EXECUTE(@Cmd )        DROP TABLE #DatabaseRoleMemberShip 