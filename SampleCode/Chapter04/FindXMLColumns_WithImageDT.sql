SET NOCOUNT ON;

DECLARE @SQL nvarchar(1000),
	 @tblName nvarchar(200),
	 @clmnName nvarchar(100),
	 @DType nvarchar(100)

IF (OBJECT_ID('tempdb.dbo.#Result')) IS NOT NULL
	DROP TABLE #Result

CREATE TABLE #Result (XMLValue XML,
		TopElement nvarchar(100),
		tblName nvarchar(200),
		clmnName nvarchar(100),
		DateType nvarchar(100))

IF (OBJECT_ID('tempdb.dbo.#XML')) IS NOT NULL
	DROP TABLE #XML

CREATE TABLE #XML (Val XML, TopElmn varchar(100))

DECLARE cur CURSOR
	FOR
SELECT XMLClmn = ';WITH CTE AS
(SELECT TOP 1 '+ CASE t.name WHEN 'image' THEN ' TRY_CONVERT(XML, CAST(' + QUOTENAME(c.name)  + ' as varbinary(max))) as tst, '
	ELSE ' TRY_CONVERT(XML, ' + QUOTENAME(c.name)  + ') as tst, ' END + QUOTENAME(c.name)  + ' FROM ' 
	+ QUOTENAME(s.name) +'.' + QUOTENAME(o.name) +
	' 
WHERE '+ CASE t.name WHEN 'image' THEN ' TRY_CONVERT(XML, CAST(' + QUOTENAME(c.name)  + ' as varbinary(max)))'
	ELSE ' TRY_CONVERT(XML, ' + QUOTENAME(c.name)  + ') ' END +' IS NOT NULL 
)
SELECT TOP 1 tst, c.value(''local-name(.)[1]'', ''VARCHAR(200)'') AS TopNodeName
FROM CTE CROSS APPLY tst.nodes(''/*'') AS t(c);' 
	,TableName = s.name + '.' + o.name
	,ColumneName = c.name 
	,t.name
FROM sys.columns c 
JOIN sys.types t on c.system_type_id = t.system_type_id
	JOIN sys.objects o ON c.object_id = o.object_id AND o.type = 'u'
	JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE (t.name IN('xml','varchar', 'nvarchar', 'varbinary') and c.max_length = -1) 
	OR (t.name IN ('image', 'text', 'ntext'))

OPEN cur

FETCH NEXT FROM cur INTO @SQL, @tblName, @clmnName, @DType

WHILE @@FETCH_STATUS = 0
BEGIN

	INSERT #XML
	EXEC(@SQL)

	INSERT #Result
	SELECT Val, TopElmn, @tblName, @clmnName, @DType
	FROM #XML

	TRUNCATE TABLE #XML

	FETCH NEXT FROM cur INTO @SQL, @tblName, @clmnName, @DType
END

DEALLOCATE cur;

SELECT XMLValue,TopElement,tblName,clmnName,DateType 
FROM #Result

DROP TABLE #Result
DROP TABLE #XML

SET NOCOUNT OFF;
