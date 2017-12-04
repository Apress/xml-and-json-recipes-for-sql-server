--USE AdventureWorks;

-- Listing 4-1. Shredding the XML with the OPENXML function.
DECLARE @xml nvarchar(max),
	@idoc int,
	@ns varchar(200) = 
N'<root xmlns:df="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelManuInstructions" />';

SELECT @xml = cast(Instructions as nvarchar(max)) 
FROM [Production].[ProductModel] 
WHERE ProductModelID = 7;

EXECUTE sp_xml_preparedocument @idoc OUTPUT, @xml, @ns;

SELECT StepInstruction,
LaborStation,
LaborHours,
LotSize,
MachineHours,
SetupHours,
Material,
Tool
FROM OPENXML(@idoc, 'df:root/df:Location/df:step', 2)
WITH (
	LaborStation INT '../@LocationID',
	LaborHours REAL '../@LaborHours',
	LotSize INT '../@LotSize ',
	MachineHours REAL '../@MachineHours ',
	SetupHours REAL '../@SetupHours ',
	Material VARCHAR(100) 'df:material',
	Tool VARCHAR(100) 'df:tool',
	StepInstruction VARCHAR(2000) '.'
	);

EXECUTE sp_xml_removedocument @idoc;
GO

-- Listing 4-9. Migrating OPENXML into XQuery. 
DECLARE @xml XML;

SELECT @xml = Instructions
FROM [Production].[ProductModel] 
WHERE ProductModelID = 7;

WITH XMLNAMESPACES('http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelManuInstructions' as df)
SELECT RTRIM(LTRIM(REPLACE(instruct.value('.', 'VARCHAR(2000)'), CHAR(10), ''))) AS StepInstruction,
	instruct.value('../@LocationID', 'INT') AS LaborStation,
	instruct.value('../@LaborHours', 'REAL') AS LaborHours,
	instruct.value('../@LotSize', 'INT') AS LotSize,
	instruct.value('../@MachineHours', 'REAL') AS MachineHours,
	instruct.value('../@SetupHours', 'REAL') AS SetupHours,
	instruct.value('df:material[1]', 'VARCHAR(100) ') AS Material,
	instruct.value('df:tool[1]', 'VARCHAR(100) ') AS Tool
FROM @xml.nodes('df:root/df:Location/df:step') prod(instruct);

/*
-- Listing 4-13. Shredding the XML document with DEFAULT xml namespace and again with “df” prefix. 
WITH XMLNAMESPACES(DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelManuInstructions')
SELECT RTRIM(LTRIM(REPLACE(instruct.value('.', 'varchar(2000)'), CHAR(10), ''))) AS StepInstruction
	instruct.value('../@LocationID', 'int') AS LaborStation,
	instruct.value('../@LaborHours', 'real') AS LaborHours,
	instruct.value('../@LotSize', 'int') AS LotSize,
	instruct.value('../@MachineHours', 'real') AS MachineHours,
	instruct.value('../@SetupHours', 'real') AS SetupHours,
	instruct.value('material[1]', 'varchar(100) ') AS Material,
	instruct.value('tool[1]', 'varchar(100) ') AS Tool
FROM @xml.nodes('root/Location/step') prod(instruct);

*/

-- Listing 4-15. Showing the XQuery code to return the result set from the XML column.
WITH XMLNAMESPACES(default 'http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/StoreSurvey')
SELECT details.value('AnnualSales[1]', 'MONEY') AS AnnualSales,
	details.value('AnnualRevenue[1]', 'MONEY') AS AnnualRevenue,
	details.value('BankName[1]', 'VARCHAR(50)') AS BankName,
	details.value('BusinessType[1]', 'VARCHAR(10)') AS BusinessType,
	details.value('YearOpened[1]', 'INT') AS YearOpened,
	details.value('Specialty[1]', 'VARCHAR(50)') AS Specialty,
	details.value('SquareFeet[1]', 'INT') AS SquareFeet,
	details.value('Brands[1]', 'VARCHAR(10)') AS Brands,
	details.value('Internet[1]', 'VARCHAR(10)') AS Internet,
	details.value('NumberEmployees[1]', 'SMALLINT') AS NumberEmployees
FROM Sales.Store
CROSS APPLY Demographics.nodes('StoreSurvey') survey(details);

-- Listing 4-16. Shredding XML variable.
DECLARE @x XML;

SELECT @x = Demographics 
FROM Sales.Store 
WHERE BusinessEntityID = 292;

WITH XMLNAMESPACES(default 'http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/StoreSurvey')
SELECT details.value('AnnualSales[1]', 'MONEY') AS AnnualSales,
	details.value('AnnualRevenue[1]', 'MONEY') AS AnnualRevenue,
	details.value('BankName[1]', 'VARCHAR(50)') AS BankName,
	details.value('BusinessType[1]', 'VARCHAR(10)') AS BusinessType,
	details.value('YearOpened[1]', 'INT') AS YearOpened,
	details.value('Specialty[1]', 'VARCHAR(50)') AS Specialty,
	details.value('SquareFeet[1]', 'INT') AS SquareFeet,
	details.value('Brands[1]', 'VARCHAR(10)') AS Brands,
	details.value('Internet[1]', 'VARCHAR(10)') AS Internet,
	details.value('NumberEmployees[1]', 'SMALLINT') AS NumberEmployees
FROM @x.nodes('StoreSurvey') survey(details);

-- Listing 4-18. Shredding SSIS package code.
WITH XMLNAMESPACES ('www.microsoft.com/SqlServer/Dts' AS DTS, 
	'www.microsoft.com/sqlserver/dts/tasks/sqltask' AS SQLTask),
Package 
AS 
(
	SELECT name,
		CAST(CAST(packagedata AS VARBINARY(MAX)) AS XML) AS package
	FROM msdb.dbo.sysssispackages
	WHERE packagetype = 6
)
SELECT Package.name as MaintenancePlanName,
    PKG.value('@SQLTask:DatabaseName', 'NVARCHAR(128)')  AS DatabaseName,
    PKG.value('(../@SQLTask:BackupDestinationAutoFolderPath)', 'NVARCHAR(500)') AS BackupDestinationFolderPath
FROM Package
CROSS APPLY package.nodes('//DTS:ObjectData/SQLTask:SqlTaskData/SQLTask:SelectedDatabases') SSIS(PKG);

-- Listing 4-21. Applying the fn:string() function to fix Msg 9314 error.
WITH XMLNAMESPACES('http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelManuInstructions' as df)
SELECT ProductModelID,
	instruct.value('fn:string(.)', 'varchar(2000)') AS StepInstruction,
	instruct.value('fn:string(../@LocationID)', 'int') AS LaborStation,
	instruct.value('fn:string(../@LaborHours)', 'real') AS LaborHours,
	instruct.value('fn:string(../@LotSize)', 'int') AS LotSize,
	instruct.value('fn:string(../@MachineHours)', 'real') AS MachineHours,
	instruct.value('fn:string(../@SetupHours)', 'real') AS SetupHours,
	instruct.value('df:material[1]', 'varchar(100) ') AS Material,
	instruct.value('df:tool[1]', 'varchar(100) ') AS Tool
FROM Production.ProductModel
CROSS APPLY Instructions.nodes('df:root/df:Location/df:step') prod(instruct);
GO

-- Listing 4-22. Analyzing the data accessor functions. A query() method covered in the next recipe 4-6 Retrieving a Ssubset of Your XML  Data.
DECLARE @x XML = '<top>
	<level1>1</level1>
	<level2>2</level2>
</top>
<!-- second reference to <top> element -->
<top><level3>3</level3></top>';

SELECT @x.query('/top/level1/text()') Text_Function,
	@x.query('fn:data(/*)') Data_Function,
	@x.query('fn:string(/*[1])') String_Function;

-- Listing 4-23. Demonstrating result difference between text() and fn:string() functions.
WITH XMLNAMESPACES('http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelManuInstructions' as df)
SELECT instruct.value('./text()[1]', 'varchar(2000)') AS Step_Instruction_by_text,
	instruct.value('fn:string(.)', 'varchar(2000)') AS Step_Instruction_by_string
FROM Production.ProductModel
CROSS APPLY Instructions.nodes('df:root/df:Location/df:step') prod(instruct);

-- Listing 4-24. Returning SQL Statements XML from the Execution Plan. 
SELECT TOP (25)
	@@SERVERNAME as ServerName,
	qs.Execution_count as Executions,
	qs.total_worker_time as TotalCPU,
	qs.total_physical_reads as PhysicalReads,
	qs.total_logical_reads as LogicalReads,
	qs.total_logical_writes as LogicalWrites,
	qs.total_elapsed_time as Duration,
	qs.total_worker_time/qs.execution_count as [Avg CPU Time],
	DB_NAME(qt.dbid) DatabaseName,
	qt.objectid,
	OBJECT_NAME(qt.objectid, qt.dbid) ObjectName,
	qp.query_plan  as XMLPlan,
	query_plan.query('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/showplan";//Batch/Statements') as SQLStatements
FROM sys.dm_exec_query_stats qs
	CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
	CROSS APPLY sys.dm_exec_query_plan(plan_handle) as qp
WHERE qt.dbid IS NOT NULL
ORDER BY TotalCPU DESC;
GO

-- Listing 4-25. Returning Features subset fromthe XML.
DECLARE @x XML ='<ProductDescription>
	<Manufacturer>
		<Name>AdventureWorks</Name>
		<Copyright>2002</Copyright>
		<ProductURL>HTTP://www.Adventure-works.com</ProductURL>
	</Manufacturer>
	<Features>
		<Warranty>
			<WarrantyPeriod>3 years</WarrantyPeriod>
			<Description>parts and labor</Description>
		</Warranty><Maintenance>
			<NoOfYears>10 years</NoOfYears>
			<Description>maintenance contract available through your dealer or any AdventureWorks retail store.</Description>
		</Maintenance>
	</Features>
	<Picture>
		<Angle>front</Angle>
		<Size>small</Size>
		<ProductPhotoID>118</ProductPhotoID>
	</Picture>
</ProductDescription>';

SELECT @x.query('ProductDescription/Features');

-- Listing 4-27. Declaring multiple namespaces in XQuery, in the query() method.
SELECT name,
	CAST(CAST(packagedata AS varbinary(MAX)) AS XML) AS package,
	CAST(CAST(packagedata AS varbinary(MAX)) AS XML).query('declare namespace 	DTS="www.microsoft.com/SqlServer/Dts";
declare namespace SQLTask="www.microsoft.com/sqlserver/dts/tasks/sqltask"; 
		//DTS:ObjectData//SQLTask:SqlTaskData/SQLTask:SelectedDatabases') as SQLStatements
FROM msdb.dbo.sysssispackages
WHERE packagetype = 6;

-- Listing 4-28. Using XMLNAMESPACES instead of XQuery namespace declaration in the query() method.
WITH XMLNAMESPACES('www.microsoft.com/SqlServer/Dts' as DTS,
'www.microsoft.com/sqlserver/dts/tasks/sqltask' as SQLTask)
SELECT name,
	CAST(CAST(packagedata AS varbinary(MAX)) AS XML) AS package,
	CAST(CAST(packagedata AS varbinary(MAX)) AS XML).query('//DTS:ObjectData//SQLTask:SqlTaskData/SQLTask:SelectedDatabases') as SQLStatements
FROM msdb.dbo.sysssispackages
WHERE packagetype = 6;

-- Listing 4-29. Returning query() function result with user-defined root element.
WITH XMLNAMESPACES('www.microsoft.com/SqlServer/Dts' as DTS,
'www.microsoft.com/sqlserver/dts/tasks/sqltask' as SQLTask)
SELECT name,
	CAST(CAST(packagedata AS varbinary(MAX)) AS XML) AS package,
	CAST(CAST(packagedata AS varbinary(MAX)) AS XML).query('<Root>{//DTS:ObjectData//SQLTask:SqlTaskData/SQLTask:SelectedDatabases}</Root>') as SQLStatements
FROM msdb.dbo.sysssispackages
WHERE packagetype = 6;

-- Listing 4-30. Detecting the XML document across the tables and columns.
SET NOCOUNT ON;

DECLARE @SQL nvarchar(1000),
	 @tblName nvarchar(200),
	 @clmnName nvarchar(100),
	 @DType nvarchar(100);

IF (OBJECT_ID('tempdb.dbo.#Result')) IS NOT NULL
	DROP TABLE #Result;

CREATE TABLE #Result 
(
	XMLValue XML,
	TopElement NVARCHAR(100),
	tblName NVARCHAR(200),
	clmnName NVARCHAR(100),
	DateType NVARCHAR(100)
);

IF (OBJECT_ID('tempdb.dbo.#XML')) IS NOT NULL
	DROP TABLE #XML;

CREATE TABLE #XML 
(
	Val XML, 
	TopElmn VARCHAR(100)
);

DECLARE cur 
CURSOR FOR
SELECT XMLClmn = 'WITH CTE AS
(SELECT TOP 1 '+ CASE t.name WHEN 'IMAGE' THEN ' TRY_CONVERT(XML, CAST(' + QUOTENAME(c.name)  + ' AS VARBINARY(MAX))) AS tst, '
	ELSE ' TRY_CONVERT(XML, ' + QUOTENAME(c.name)  + ') as tst, ' END + QUOTENAME(c.name)  + ' FROM ' 
	+ QUOTENAME(s.name) +'.' + QUOTENAME(o.name) +
	' 
WHERE '+ CASE t.name WHEN 'IMAGE' THEN ' TRY_CONVERT(XML, CAST(' + QUOTENAME(c.name)  + ' AS VARBINARY(MAX)))'
	ELSE ' TRY_CONVERT(XML, ' + QUOTENAME(c.name)  + ') ' END +' IS NOT NULL 
)
SELECT TOP (1) tst, 
	c.value(''fn:local-name(.)[1]'', ''VARCHAR(200)'') AS TopNodeName
FROM CTE CROSS APPLY tst.nodes(''/*'') AS t(c);',
	s.name + '.' + o.name AS TableName,
	c.name AS ColumnName,
	t.name
FROM sys.columns c 
INNER JOIN sys.types t 
	ON c.system_type_id = t.system_type_id
INNER JOIN sys.objects o 
	ON c.object_id = o.object_id 
	AND o.type = 'u'
INNER JOIN sys.schemas s 
	ON s.schema_id = o.schema_id
WHERE (t.name IN('xml','varchar', 'nvarchar', 'varbinary') AND c.max_length = -1) 
	OR (t.name IN ('image', 'text', 'ntext'));

OPEN cur;

FETCH NEXT 
FROM cur 
INTO @SQL, @tblName, @clmnName, @DType;

WHILE @@FETCH_STATUS = 0
BEGIN

	INSERT INTO #XML
	EXEC(@SQL);

	INSERT #Result
	SELECT Val, TopElmn, @tblName, @clmnName, @DType
	FROM #XML;

	TRUNCATE TABLE #XML;

	FETCH NEXT FROM cur INTO @SQL, @tblName, @clmnName, @DType;
END

DEALLOCATE cur;

SELECT XMLValue,TopElement,tblName,clmnName,DateType 
FROM #Result;

DROP TABLE #Result;
DROP TABLE #XML;

SET NOCOUNT OFF;
GO

-- Listing 4-31. Verifying IMAGE data type.
WITH CTE AS
(
	SELECT TOP (1) TRY_CONVERT(XML, CAST(packagedata AS VARBINARY(MAX))) AS tst,
		packagedata
	FROM msdb.dbo.sysssispackages
	WHERE  TRY_CONVERT(XML, CAST(packagedata AS VARBINARY(MAX))) IS NOT NULL 
)
SELECT TOP (1) tst, 
	c.value('local-name(.)[1]', 'VARCHAR(200)') AS TopNodeName
FROM CTE 
CROSS APPLY tst.nodes('/*') AS t(c);

--Listing 4-32. Verifying VARCHAR, NVARCHAR, VARBINARY, TEXT, and NTEXT data types
WITH CTE AS
(
	SELECT TOP (1) TRY_CONVERT(XML, expression) as tst, 
		expression 
	FROM msdb.dbo.syspolicy_conditions_internal 
	WHERE  TRY_CONVERT(XML, expression) IS NOT NULL 
)
SELECT TOP (1) tst, 
	c.value('fn:local-name(.)[1]', 'VARCHAR(200)') AS TopNodeName
FROM CTE 
CROSS APPLY tst.nodes('/*') AS t(c);


-- Listing 4-33. Displaying all the elements from the XML data.
WITH ALLELEMENTS 
AS
(
	SELECT TOP 1 Demographics
	FROM Sales.Store
)
SELECT
	details.value('local-name(..)[1]', 'VARCHAR(100)') AS ParentNodeName,
	details.value('local-name(.)[1]', 'VARCHAR(100)') AS NodeName
FROM ALLELEMENTS
	CROSS APPLY Demographics.nodes('//*') survey(details);

-- Listing 4-34. Demonstrating multiple CROSS APPLY operator solution.
WITH XMLNAMESPACES('http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelManuInstructions' as df)
SELECT ProductModelID,
	step.value('fn:string(.)', 'varchar(2000)') AS StepInstruction,
	instruct.value('@LocationID', 'int') AS LaborStation,
	instruct.value('@LaborHours', 'real') AS LaborHours,
	instruct.value('@LotSize', 'int') AS LotSize,
	instruct.value('@MachineHours', 'real') AS MachineHours,
	instruct.value('@SetupHours', 'real') AS SetupHours,
	step.value('df:material[1]', 'varchar(100) ') AS Material,
	step.value('df:tool[1]', 'varchar(100) ') AS Tool
FROM Production.ProductModel 
	CROSS APPLY Instructions.nodes('df:root/df:Location') prod(instruct)
	CROSS APPLY instruct.nodes('df:step') ins(step);

