/********************************************* XML INSERT ************************************************************************************/
SET NOCOUNT ON;

DECLARE @XML XML,
		@schema nvarchar(30),
		@tbl nvarchar(128),
		@objID int,
		@time datetime2

DROP TABLE IF EXISTS dbo.Table_Info_XML;

CREATE TABLE Table_Info_XML (
		TableID int PRIMARY KEY,
		DBName nvarchar(128),
		[SchemaName] nvarchar(30),
		tblName nvarchar(128),
		XMLDoc XML
		);

DECLARE cur CURSOR FOR
	SELECT object_id, [Schema].name, [Table].name 
	FROM sys.objects [Table] 
		JOIN sys.schemas [Schema] on [Table].schema_id = [Schema].schema_id
	WHERE type = 'u';

OPEN cur;

FETCH NEXT FROM cur INTO @objID, @schema, @tbl;
SET @time = GETDATE();
WHILE @@FETCH_STATUS = 0
BEGIN


	SELECT @XML = (
	SELECT db_name() as 'Database',
	[Schema].name as 'Tables/SchemaName',
	[Table].name as 'Tables/TableName', 
		(SELECT name as ColumnName FROM sys.columns [Column] 
		WHERE [Column].object_id = [Table].object_id FOR XML AUTO, TYPE
		) AS 'Tables/Columns' 
	FROM sys.objects [Table] 
		JOIN sys.schemas [Schema] on [Table].schema_id = [Schema].schema_id
	WHERE [Table].object_id = @objID 
	FOR XML PATH('TableInfo')
	);

	INSERT Table_Info_XML
	SELECT @objID, DB_NAME(), @schema, @tbl, @XML;

	FETCH NEXT FROM cur INTO @objID, @schema, @tbl;
END;

DEALLOCATE cur;
SELECT DATEDIFF(MILLISECOND, @time, getdate()) as XML_TIME
SET NOCOUNT OFF;

GO
/********************************************* JSON INSERT ************************************************************************************/


SET NOCOUNT ON;

DECLARE @JSON nvarchar(MAX),
		@schema nvarchar(30),
		@tbl nvarchar(128),
		@objID int,
		@time datetime2

DROP TABLE IF EXISTS dbo.Table_Info;

CREATE TABLE Table_Info (
		TableID int PRIMARY KEY,
		DBName nvarchar(128),
		[SchemaName] nvarchar(30),
		tblName nvarchar(128),
		JSONDoc nvarchar(MAX)
		);

DECLARE cur CURSOR FOR
	SELECT object_id, [Schema].name, [Table].name 
	FROM sys.objects [Table] 
		JOIN sys.schemas [Schema] on [Table].schema_id = [Schema].schema_id
	WHERE type = 'u';

OPEN cur;

FETCH NEXT FROM cur INTO @objID, @schema, @tbl;
SET @time = GETDATE();
WHILE @@FETCH_STATUS = 0
BEGIN


	SELECT @JSON = (
	SELECT db_name() as 'Database',
	[Schema].name as 'Tables.SchemaName',
	[Table].name as 'Tables.TableName', 
		(SELECT [Column].name ColumnName FROM sys.columns [Column] 
		WHERE [Column].object_id = [Table].object_id FOR JSON AUTO
		) AS 'Tables.Columns' 
	FROM sys.objects [Table] 
		JOIN sys.schemas [Schema] on [Table].schema_id = [Schema].schema_id
	WHERE [Table].object_id = @objID 
	FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
	);

	INSERT Table_Info
	SELECT @objID, DB_NAME(), @schema, @tbl, @JSON;

	FETCH NEXT FROM cur INTO @objID, @schema, @tbl;
END;

DEALLOCATE cur;
SELECT DATEDIFF(MILLISECOND, @time, getdate()) as JSON_TIME
SET NOCOUNT OFF;

GO

/*********************************************************************************************************************************************/
--- XML
SET STATISTICS TIME ON;

select 	clm.value('../../../Database[1]', 'varchar(50)') as [Database]
	,clm.value('../../SchemaName[1]', 'varchar(50)') as SchemaName
	,clm.value('../../TableName[1]', 'varchar(50)') as TableName
	,clm.value('@ColumnName', 'varchar(50)') as ColumnName
from Table_Info_XML
	CROSS APPLY XMLDoc.nodes('TableInfo/Tables/Columns/Column') as tbl(clm);

SET STATISTICS TIME OFF;

--- JSON
SET STATISTICS TIME ON;

   SELECT db.[Database]    -- first level
	, tbl.SchemaName -- second level
	, tbl.TableName  -- second level
	, clmn.ColumnName -- third level
FROM [dbo].[Table_Info]
	CROSS APPLY OPENJSON (JSONDoc)
		WITH
		(
			[Database] varchar(30), 
			[Tables] nvarchar(MAX) AS JSON	
		) as db
CROSS APPLY OPENJSON ([Tables]) 
		WITH 
		(
			TableName varchar(30),
			SchemaName varchar(30),
			[Columns] nvarchar(MAX) AS JSON
		) as tbl
CROSS APPLY OPENJSON ([Columns])
		WITH 
		(
			ColumnName varchar(30)
		) as clmn

SET STATISTICS TIME OFF;
