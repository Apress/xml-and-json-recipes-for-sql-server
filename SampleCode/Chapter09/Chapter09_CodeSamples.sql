USE [WideWorldImporters];

-- Listing 9-1 Detecting JSON data
SET NOCOUNT ON;

DECLARE @SQL nvarchar(1000)

IF (OBJECT_ID('tempdb.dbo.#Result')) IS NOT NULL
	DROP TABLE #Result

CREATE TABLE #Result (tblName nvarchar(200),
		clmnName nvarchar(100),
		DateType nvarchar(100),
		JSONDoc nvarchar(MAX),)

DECLARE cur CURSOR
	FOR
SELECT 'SELECT TOP (1) ''' + QUOTENAME(s.name) +'.' + QUOTENAME(o.name) + ''' as TblName, ''' 
+ QUOTENAME(c.name)  + ''' as ClmName, '''
+ t.name  + QUOTENAME(case c.max_length when -1 then 'MAX' ELSE cast(c.max_length as varchar(5)) END , ')') + ''' as DataType, '
+ QUOTENAME(c.name)  + ' FROM ' 
	+ QUOTENAME(s.name) +'.' + QUOTENAME(o.name) +
	' WHERE ISJSON(' + QUOTENAME(c.name)  + ') = 1;' 
FROM sys.columns c 
JOIN sys.types t on c.system_type_id = t.system_type_id
	JOIN sys.objects o ON c.object_id = o.object_id AND o.type = 'u'
	JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE t.name IN('varchar', 'nvarchar') 
AND (c.max_length = -1 OR c.max_length > 100)

OPEN cur

FETCH NEXT FROM cur INTO @SQL

WHILE @@FETCH_STATUS = 0
BEGIN

	print @SQL
	INSERT #Result
	EXEC(@SQL)

	FETCH NEXT FROM cur INTO @SQL
END

DEALLOCATE cur;

SELECT JSONDoc,tblName,clmnName,DateType 
FROM #Result
ORDER BY tblName, clmnName

DROP TABLE #Result

SET NOCOUNT OFF;

-- Listing 9-5 Returning Events arrays 
SELECT TOP (1) JSON_QUERY([ReturnedDeliveryData], '$.Events')
FROM [Sales].[Invoices];

-- Listing 9-8 Referencing a single JSON array object.
SELECT TOP (1) JSON_QUERY([ReturnedDeliveryData], '$.Events[0]')
FROM [Sales].[Invoices];

-- Listing 9-10 Returning scalar values.
SELECT TOP (1) JSON_value([ReturnedDeliveryData], '$.ReceivedBy') ReceivedBy
	,JSON_value([ReturnedDeliveryData], '$.Events[0].Event') FirstEvent
	,JSON_value([ReturnedDeliveryData], '$.Events[0].EventTime') EventTime
	,JSON_value([ReturnedDeliveryData], '$.Events[1].Event') LastEvent
	,JSON_value([ReturnedDeliveryData], '$.Events[1].Status') [Status]
FROM [Sales].[Invoices];

-- Listing 9-11 Demonstrating JSON_VALUE() and JSON_QUERY() functions.
SELECT TOP (1) JSON_VALUE([ReturnedDeliveryData], '$.ReceivedBy') ScalarValue
	,JSON_QUERY([ReturnedDeliveryData], '$.ReceivedBy') ScalarQuery
	,JSON_VALUE([ReturnedDeliveryData], '$.Events[0]') ObjectValue
	,JSON_QUERY([ReturnedDeliveryData], '$.Events[0]') ObjectQuery
FROM [Sales].[Invoices];

-- Listing 9-12 Verifying the returned data type by JSON_VALUE() function. 
DECLARE @Value sql_variant

SELECT @Value = 
(
SELECT TOP (1) JSON_value([ReturnedDeliveryData], '$."ReceivedBy"') 
FROM [Sales].[Invoices]
);

SELECT SQL_VARIANT_PROPERTY(@Value,'BaseType') BaseType, 
CAST(SQL_VARIANT_PROPERTY(@Value, 'MaxLength')as int) / 
	CASE SQL_VARIANT_PROPERTY(@Value,'BaseType') WHEN 'nvarchar' 
						THEN 2 ELSE 1 END TypeLength,
SQL_VARIANT_PROPERTY(@Value,'TotalBytes') TotalBytes;

-- Listing 9-13 Demonstrating how text that exceeds the character limit affects the JSON_VALUE() function output.
declare @json nvarchar(max) = '
{
"RegularText":"Regular Text",

"LongText":"Long Text' + REPLICATE(' too long ', 500) + '"
}'
SELECT JSON_VALUE(@json, '$.RegularText') RegularText , 
JSON_VALUE(@json, '$.LongText') LongText
GO

-- Listing 9-14 Forcing a JSON_VALUE() function to raise an error.
SELECT JSON_VALUE([ReturnedDeliveryData], 'strict $.receivedby') ReceivedBy
FROM [Sales].[Invoices];

-- Listing 9-16 Implementing strict mode
declare @json nvarchar(max) = '
{
"RegularText":"Regular Text",

"LongText":"Long Text' + REPLICATE(' too long ', 500) + '"
}'
SELECT JSON_VALUE(@json, 'strict $.LongText') LongText

-- Listing 9-18 Converting JSON into table structure
SELECT UserPref.theme,
	UserPref.[dateFormat],
	UserPref.timeZone, 
	UserPref.pagingType,
	UserPref.pageLength,
	UserPref.favoritesOnDashboard
FROM [Application].[People]
	CROSS APPLY OPENJSON([UserPreferences])
	WITH
	(
		theme		varchar(20) '$.theme',
		[dateFormat] varchar(20) '$.dateFormat',
		timeZone	varchar(10) '$.timeZone', 
		pagingType	varchar(20) '$.table.pagingType',
		pageLength	int	     '$.table.pageLength',
		favoritesOnDashboard bit '$.favoritesOnDashboard'
	) AS UserPref;

-- Listing 9-20 Shredding a JSON document with default first level keys 
SELECT UserPref.theme,
	UserPref.[dateFormat],
	UserPref.timeZone, 
	UserPref.pagingType,
	UserPref.pageLength,
	UserPref.favoritesOnDashboard
FROM [Application].[People]
	CROSS APPLY OPENJSON([UserPreferences])
	WITH
	(
		theme		varchar(20),
		[dateFormat] varchar(20),
		timeZone	varchar(10), 
		pagingType	varchar(20) '$.table.pagingType',
		pageLength	int	     '$.table.pageLength',
		favoritesOnDashboard bit 
	) AS UserPref;

-- Listing 9-21 Running the OPENJSON() function without an optional argument or WITH clause  
declare @json varchar(max) =
'{
  "theme": "blitzer",
  "dateFormat": "yy-mm-dd",
  "timeZone": "PST",
  "table": {
    "pagingType": "full_numbers",
    "pageLength": 25
  	    },
  "favoritesOnDashboard": true
}'

SELECT [key], [value], [type]
FROM OPENJSON(@json);
GO

-- Listing 9-22 Shredding multiple JSON sub-object solution
SET NOCOUNT ON;

DECLARE @JSON nvarchar(MAX),
		@schema nvarchar(30),
		@tbl nvarchar(128),
		@objID int

DROP TABLE IF EXISTS dbo.Table_Info_JSON;

CREATE TABLE Table_Info_JSON (
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

	INSERT Table_Info_JSON
	SELECT @objID, DB_NAME(), @schema, @tbl, @JSON;

	FETCH NEXT FROM cur INTO @objID, @schema, @tbl;
END;

DEALLOCATE cur;

SET NOCOUNT OFF;

SELECT db.[Database]    -- first level
	, tbl.SchemaName -- second level
	, tbl.TableName  -- second level
	, clmn.ColumnName -- third level
FROM dbo.Table_Info_JSON
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
		) as clmn;

-- Listing 9-25 Creating an index for JSON key-value ConNote. 
USE [WideWorldImporters];

SET ANSI_NULLS ON;

ALTER TABLE [Sales].[Invoices] ADD ConNote AS 
	CAST(JSON_VALUE([ReturnedDeliveryData], '$.Events[0].ConNote') AS varchar(20)) PERSISTED 

CREATE  INDEX IX_Sales_Invoices_ConNote
ON [Sales].[Invoices] 
	(
		[ConNote]
	)INCLUDE(	
	[InvoiceDate]
	,[DeliveryInstructions]
	,[TotalDryItems]
	,[TotalChillerItems]
	,[ConfirmedDeliveryTime]
	,[ConfirmedReceivedBy]
	); 

