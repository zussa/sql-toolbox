EXEC monitor.dbo.stpCopia_Permissoes 
    @Usuario_Origem = 'usuario_origem', -- varchar(max)
    @Usuario_Destino = 'usuario_destino', -- varchar(max)
    @Database = NULL, -- varchar(max)
    @Fl_Remover_Permissoes = 1, -- bit
    @Fl_Cria_Usuarios = 1, -- bit
    @Fl_Exibe_Resultados = 1, -- bit
    @Fl_Executar = 0 -- bit



Use master
GO

DECLARE @dbname VARCHAR(50)   
DECLARE @user   VARCHAR(50)   = 'usuario'
DECLARE @statement NVARCHAR(max)

DECLARE db_cursor CURSOR 
LOCAL FAST_FORWARD
FOR  
SELECT name
FROM MASTER.dbo.sysdatabases
WHERE name NOT IN ('master','model','msdb','tempdb','distribution')  
OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @dbname  
WHILE @@FETCH_STATUS = 0  
BEGIN  

SELECT @statement = 'use '+@dbname +';'+ 'CREATE USER ['+ @user + '] FOR LOGIN ['+ @user + ']; EXEC sp_addrolemember N''db_datareader'',['+ @user + '];'

--exec sp_executesql @statement
print @statement

FETCH NEXT FROM db_cursor INTO @dbname  
END  
CLOSE db_cursor  
DEALLOCATE db_cursor 