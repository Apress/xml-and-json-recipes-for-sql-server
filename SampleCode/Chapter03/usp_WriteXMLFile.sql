CREATE PROC usp_WriteXMLFile
	@FilePath nvarchar(100)
AS

IF (object_id('tempdb.dbo.##XML') IS NOT NULL)
	DROP TABLE ##XML

CREATE TABLE ##XML (XMLHolder XML)

INSERT ##XML
SELECT (
SELECT ProductCategory.Name AS "Category/CategoryName",
	(SELECT DISTINCT Location.Name "text()", ', cost rate $',
			Location.CostRate "text()"
	FROM Production.ProductInventory Inventory 
		INNER JOIN Production.Location Location
			ON Inventory.LocationID = Location.LocationID 
	WHERE Product.ProductID = Inventory.ProductID 
	FOR XML PATH('LocationName'), TYPE) AS "Locations/node()",
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
	ON Subcategory.ProductCategoryID = Production.ProductCategory.ProductCategoryID
ORDER BY ProductCategory.Name, Subcategory.Name, Product.Name
FOR XML PATH('Categories'), ELEMENTS XSINIL, ROOT('Products')
);

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

declare @SQL nvarchar(300) = ''

SET @SQL = 'bcp tempdb.dbo.##XML out "' + @FilePath + '\Categories.xml" -S "' + cast(SERVERPROPERTY('ServerName') as nvarchar(50))+ '" -T -c'

exec master..xp_cmdshell 'bcp tempdb.dbo.##XML out "C:\Temp\Categories.xml" -S "SQL_AG" -T -c'

IF @run_value = 0
BEGIN
-- Disable xp_cmdshell
	EXEC sp_configure 'xp_cmdshell', 0
	RECONFIGURE
END

IF (object_id('tempdb.dbo.##XML') IS NOT NULL)
	DROP TABLE ##XML

GO

-- exec usp_WriteXMLFile 'C:\temp'

