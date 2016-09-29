--Generates a list of ALTER statements for moving files. Especially helpful for TempDB (which can have many files)
USE master;
GO
DECLARE 
  @DBName varchar(128) = 'tempdb',
	@DataFileFolder varchar(256) = 'N:\SQL_Data\',
	@LogFileFolder varchar(256) = 'N:\SQL_Log\'
	;
select 'ALTER DATABASE ' + quotename(@DBName) + '
MODIFY FILE (NAME = ' + name + ', FILENAME = ''' + 
	CASE WHEN mf.type_desc <> 'LOG' THEN @DataFileFolder
		ELSE @LogFileFolder
		END + 
	 REVERSE(SUBSTRING(REVERSE(LTRIM(RTRIM(physical_name))),
				1,
				CHARINDEX('\', REVERSE(LTRIM(RTRIM(physical_name))))-1
				)
			)
		 + 
	 ''');',* 
from sys.master_files mf where mf.database_id = db_id(@DBName)
GO 


