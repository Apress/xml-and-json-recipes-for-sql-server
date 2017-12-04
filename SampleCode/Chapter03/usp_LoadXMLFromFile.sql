CREATE PROC usp_LoadXMLFromFile
	@FilePath nvarchar(100)
AS

-- Prepare log table
declare @cmd TABLE (name nvarchar(35),
	minimum int,
	maximum int,
	config_value int,
	run_value int
) 
declare @run_value	int

-- Save original configuration set
INSERT @cmd
EXEC sp_configure 'xp_cmdshell'

SELECT @run_value = run_value	FROM @cmd

IF @run_value = 0
BEGIN
-- Enable xp_cmdshell
	EXEC sp_configure 'xp_cmdshell', 1
	RECONFIGURE
END

SET NOCOUNT ON

IF NOT EXISTS (SELECT * FROM sys.objects 
				WHERE object_id = OBJECT_ID(N'[dbo].[_XML]') AND type in (N'U')
				)
	CREATE TABLE _XML (XMLFileName nvarchar(300), XML_LOAD XML)
	
	TRUNCATE TABLE _XML

DECLARE	@DOS nvarchar(300) = '',
		@DirBaseLocation nvarchar(500),
		@FileName nvarchar(300),
		@SQL nvarchar(1000) = ''

DECLARE @files TABLE (tID int IDENTITY(1,1), XMLFile nvarchar(300))

-- Verify that last charachter is \
SET @DirBaseLocation = IIF(RIGHT(@FilePath, 1) = '\', '', @FilePath + '\')

SET @DOS = 'dir /B /O:-D ' + @DirBaseLocation  
INSERT @files
EXEC master..xp_cmdshell @DOS
		 
DECLARE cur CURSOR
	FOR  SELECT XMLFile 
		 FROM @files 
		 WHERE XMLFile like '%.xml'
OPEN cur

FETCH NEXT FROM cur INTO @FileName

WHILE @@FETCH_STATUS = 0
BEGIN

BEGIN TRY
	SET @SQL = 'INSERT INTO _XML SELECT ''' + @FileName 
	+ ''', X  FROM OPENROWSET(BULK N''' + @DirBaseLocation + @FileName 
	+ ''', SINGLE_BLOB) as tempXML(X)'

	exec sp_executesql @SQL
	
	FETCH NEXT FROM cur INTO @FileName
END TRY
BEGIN CATCH
	SELECT @SQL, ERROR_MESSAGE()
END CATCH
END	

DEALLOCATE cur

IF @run_value = 0
BEGIN
-- Disable xp_cmdshell
	EXEC sp_configure 'xp_cmdshell', 0
	RECONFIGURE
END

IF (object_id('tempdb.dbo.##XML') IS NOT NULL)
	DROP TABLE ##XML

GO

-- exec usp_LoadXMLFromFile 'C:\temp'

--  select * from _XML