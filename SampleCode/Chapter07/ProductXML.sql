USE [AdventureWorks]
GO


CREATE TABLE dbo.[ProductXML](
	[ProductID] int NOT NULL,
	[Name] nvarchar(50) NOT NULL,
	[ProductNumber] nvarchar(25) NOT NULL,
	[ProductDetails] XML NULL
 CONSTRAINT [PK_ProductXML_ProductID] PRIMARY KEY CLUSTERED 
	(
		[ProductID] ASC
	)
) ON [PRIMARY]

GO

SET NOCOUNT ON;

DECLARE @ProductID int,
	@Name nvarchar(50),
	@ProductNumber nvarchar(25) ,
	@ProductDetails XML;

DECLARE cur CURSOR FOR
	SELECT[ProductID], [Name], [ProductNumber] 
	FROM Production.Product Product
	ORDER BY Product.ProductID;

	OPEN cur;

	FETCH NEXT FROM cur INTO @ProductID, @Name, @ProductNumber;

WHILE @@FETCH_STATUS = 0
BEGIN

	SET @ProductDetails =
	(
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
		Inventory.Shelf AS "Category/Subcategory/Product/ProductLocation/Shelf", 
		Inventory.Bin AS "Category/Subcategory/Product/ProductLocation/Bin", 
    		Inventory.Quantity AS "Category/Subcategory/Product/ProductLocation/Quantity"
	FROM Production.Product Product
		LEFT JOIN Production.ProductInventory Inventory
		ON Product.ProductID = Inventory.ProductID 
		LEFT JOIN Production.ProductSubcategory Subcategory
		ON Product.ProductSubcategoryID = Subcategory.ProductSubcategoryID 
		LEFT JOIN Production.ProductCategory 
		ON Subcategory.ProductCategoryID = Production.ProductCategory.ProductCategoryID
	WHERE Product.ProductID = @ProductID
	ORDER BY ProductCategory.Name, Subcategory.Name, Product.Name
	FOR XML PATH('Categories'), ROOT('Products'), ELEMENTS
	)

	INSERT INTO [dbo].[ProductXML](ProductID, Name, ProductNumber, ProductDetails)
	SELECT @ProductID, @Name, @ProductNumber, @ProductDetails

	FETCH NEXT FROM cur INTO @ProductID, @Name, @ProductNumber;
END;

DEALLOCATE cur;

SET NOCOUNT OFF;
GO



--truncate table [ProductXML]
SET STATISTICS TIME ON

SELECT [ProductID],[Name],[ProductNumber],[ProductDetails]
FROM [dbo].[ProductXML]
WHERE [ProductDetails].exist('Products/Categories/Category/Subcategory/Product/ProductLocation/Quantity[.="622"]') = 1

SET STATISTICS TIME OFF

select * from [dbo].[ProductXML]
where [ProductDetails].exist('Products/Categories/Category/Subcategory/Product/ProductName[.="Adjustable Race"]') = 1





CREATE SELECTIVE XML INDEX IX_SELECTIVE_XML_ProductXML
ON ProductXML
	(
		ProductDetails
	)
FOR 
(
    Quantity = '/Products/Categories/Category/Subcategory/Product/ProductLocation/Quantity',
	ProductName = '/Products/Categories/Category/Subcategory/Product/ProductName' 
);

DROP INDEX IX_SELECTIVE_XML_ProductXML ON ProductXML

GO

CREATE XML INDEX IX_SELECTIVE_SECONDARY_XML_ProductXML 
	ON ProductXML
	(
		ProductDetails
	)
  USING XML INDEX IX_SELECTIVE_XML_ProductXML 
  FOR (Quantity);

