--USE AdventureWorks;

-- Listing 3-1 Using the stored procedure to write an XML file by destination file path
CREATE PROCEDURE dbo.usp_WriteXMLFile
	@XML XML,
	@FilePath nvarchar(200)
AS
BEGIN
	SET NOCOUNT ON;
	IF (OBJECT_ID('tempdb..##XML') IS NOT NULL)
		DROP TABLE ##XML;

	CREATE TABLE ##XML (XMLHolder XML);

	INSERT INTO ##XML
	(
		XMLHolder
	)
	SELECT @XML;

	-- Prepare log table
	DECLARE @cmd TABLE 
	(
		name NVARCHAR(35),
		minimum INT,
		maximum INT,
		config_value INT,
		run_value INT
	);

	DECLARE @run_value	INT;

	-- Save original configuration set
	EXECUTE master.dbo.sp_configure 'show advanced options', 1;
	RECONFIGURE;

	INSERT INTO @cmd
	(
		name,
		minimum,
		maximum,
		config_value,
		run_value
	)
	EXECUTE sp_configure 'xp_cmdshell';

	SELECT @run_value = run_value	
	FROM @cmd;

	IF @run_value = 0
	BEGIN
		-- Enable xp_cmdshell
		EXEC sp_configure 'xp_cmdshell', 1;
		RECONFIGURE;
	END;

	DECLARE @SQL nvarchar(300) = '';

	SET @SQL = 'bcp ##XML out "' + @FilePath + '\Categories_' 
		+ FORMAT(GETDATE(), N'yyyyMMdd_hhmmss')
		+ '.xml" -S "' + @@SERVERNAME + '" -T -c';
-- REPLACE(REPLACE(REPLACE(CONVERT(varchar(20), GETDATE(), 120), '-', ''), ' ', '_'), ':', '') 
-- for those who still using SQL Server 2008 R2 or below, use REPLACE instead of FORMAT. FORMAT function introduced in SQL 2012.
	EXECUTE master..xp_cmdshell @SQL;

	IF @run_value = 0
	BEGIN
		-- Disable xp_cmdshell
		EXECUTE sp_configure 'xp_cmdshell', 0;
		RECONFIGURE;
	END;

	IF (OBJECT_ID('tempdb..##XML') IS NOT NULL)
		DROP TABLE ##XML;

	SET NOCOUNT OFF;
END;
GO

-- To test the stored procedure , run following code:
DECLARE @x XML 

SET @x = (
	SELECT ProductCategory.Name AS "Category/CategoryName",
		(
			SELECT DISTINCT Location.Name "text()", ', cost rate $',
					Location.CostRate "text()"
			FROM Production.ProductInventory Inventory 
				INNER JOIN Production.Location Location
					ON Inventory.LocationID = Location.LocationID 
			WHERE Product.ProductID = Inventory.ProductID 
				FOR XML PATH('LocationName'), TYPE
		) AS "Locations/node()",
		Subcategory.Name AS "Category/Subcategory/SubcategoryName",
		Product.Name AS "Category/Subcategory/Product/ProductName", 
		Product.Color AS "Category/Subcategory/Product/Color",
		Inventory.Shelf AS "Category/Subcategory/Product/ProductName/@Shelf", 
		Inventory.Bin AS "Category/Subcategory/Product/ProductName/@Bin", 
		Inventory.Quantity AS "Category/Subcategory/Product/ProductName/@Quantity"
		FROM Production.Product Product
			INNER JOIN Production.ProductInventory Inventory
			ON Product.ProductID = Inventory.ProductID 
			INNER JOIN Production.ProductSubcategory Subcategory
			ON Product.ProductSubcategoryID = Subcategory.ProductSubcategoryID 
			INNER JOIN Production.ProductCategory 
			ON Subcategory.ProductCategoryID = ProductCategory.ProductCategoryID
		ORDER BY ProductCategory.Name, Subcategory.Name, Product.Name
		FOR XML PATH('Categories'), ELEMENTS XSINIL, ROOT('Products')
)

EXECUTE usp_WriteXMLFile @x, 'C:\TEMP'

--If you need to hide the completion output status, then add the following code to the stored procedure before executing the xp_cmdshell extended stored procedure: 
DECLARE @stat TABLE 
(
	BCPStat VARCHAR(500)
);
INSERT INTO @stat
(
	BCPStat
)
	
EXECUTE master..xp_cmdshell @SQL;
GO

-- Listing 3-6. Demonstrating stored procedure usp_LoadXMLFromFile.
CREATE PROCEDURE dbo.usp_LoadXMLFromFile
	@FilePath nvarchar(100)
AS
BEGIN
	SET NOCOUNT ON;
	-- Prepare log table
	DECLARE @cmd TABLE 
	(
		name NVARCHAR(35),
		minimum INT,
		maximum INT,
		config_value INT,
		run_value INT
	); 
	DECLARE @run_value	INT;

	-- Save original configuration set
	INSERT @cmd
	(
		name,
		minimum,
		maximum,
		config_value,
		run_value
	)
	EXEC sp_configure 'xp_cmdshell';

	SELECT @run_value = run_value	
	FROM @cmd;

	IF @run_value = 0
	BEGIN
		-- Enable xp_cmdshell
		EXEC sp_configure 'xp_cmdshell', 1;
		RECONFIGURE;
	END;


	IF NOT EXISTS 
	(
		SELECT * 
		FROM sys.objects 
		WHERE object_id = OBJECT_ID(N'[dbo].[_XML]') AND type in (N'U')
	)
	CREATE TABLE dbo._XML 
	(
		ID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
		XMLFileName NVARCHAR(300),
		XML_LOAD XML, 
		Created DATETIME
	)
	ELSE
		TRUNCATE TABLE dbo._XML;

	DECLARE @DOS NVARCHAR(300) = N'',
		@DirBaseLocation NVARCHAR(500),
		@FileName NVARCHAR(300),
		@SQL NVARCHAR(1000) = N'';

	DECLARE @files TABLE 
	(
		tID INT IDENTITY(1,1) NOT NULL PRIMARY KEY, 
		XMLFile NVARCHAR(300)
	);

	-- Verify that last character is \
	SET @DirBaseLocation = IIF(RIGHT(@FilePath, 1) = '\', @FilePath, @FilePath + '\');

	SET @DOS = 'dir /B /O:-D ' + @DirBaseLocation;
	INSERT @files
	(
		XMLFile
	)
	EXEC master..xp_cmdshell @DOS;

	IF @run_value = 0
	BEGIN
		-- Disable xp_cmdshell
		EXECUTE sp_configure 'xp_cmdshell', 0;
		RECONFIGURE;
	END;
		 
	DECLARE cur CURSOR
	FOR  	SELECT XMLFile 
		FROM @files 
		WHERE XMLFile like '%.xml';
	OPEN cur;

	FETCH NEXT 
	FROM cur 
	INTO @FileName;

	WHILE @@FETCH_STATUS = 0
	BEGIN

		BEGIN TRY
			SET @SQL = 'INSERT INTO _XML SELECT ''' + @DirBaseLocation + @FileName 
				+ ''', X, GETDATE()  FROM OPENROWSET(BULK N''' + @DirBaseLocation + @FileName 
				+ ''', SINGLE_BLOB) as tempXML(X)';

			EXECUTE sp_executesql @SQL;
	
			FETCH NEXT 
			FROM cur 
			INTO @FileName;
		END TRY
		BEGIN CATCH
			SELECT @SQL, ERROR_MESSAGE();
		END CATCH
	END;

	CLOSE cur;

	DEALLOCATE cur;
	SET NOCOUNT OFF;
END;
GO

-- Listing 3-7. Showing the code to execute the SSIS package from a stored procedure.
DECLARE @SourceLocation VARCHAR(200) = 'C:\\TEMP\\';
DECLARE @ArchiveLocation VARCHAR(200) = 'C:\\TEMP\\Archive\\'
		,@SQLQuery VARCHAR(500);  

SET @SQLQuery = 'DTEXEC /FILE ^"C:\SQL2016\Chapter3\CreateXMLFile\CreateXMLFile\LoadXMLFromFile.dtsx^" '
SET @SQLQuery = @SQLQuery + ' /SET \Package.Variables[SourceLocation].Value;^"'+ @SourceLocation + '^"
/SET \Package.Variables[ArchiveLocation].Value;^"'+ @ArchiveLocation + '^"';
EXEC master..xp_cmdshell @SQLQuery;

