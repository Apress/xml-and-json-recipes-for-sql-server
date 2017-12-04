--USE AdventureWorks;

-- Listing 2-1. Demonstrating RAW mode within a FOR XML clause.
SELECT Category.Name AS CategoryName, 
	Subcategory.Name AS SubcategoryName,
	Product.Name, 
	Product.ProductNumber AS Number, 
	Product.ListPrice AS Price
FROM  Production.Product Product 
	INNER JOIN Production.ProductSubcategory Subcategory 
		ON Product.ProductSubcategoryID = Subcategory.ProductSubcategoryID 
	LEFT JOIN Production.ProductCategory Category 
		ON Subcategory.ProductCategoryID = Category.ProductCategoryID
WHERE Product.ListPrice > 0 
	AND Product.SellEndDate IS NULL
ORDER BY CategoryName, SubcategoryName
FOR XML RAW;

-- Listing 2-3. Demonstrating the row tag name option of the FOR XML RAW clause.
SELECT Category.Name AS CategoryName, 
	Subcategory.Name AS SubcategoryName,
	Product.Name, 
	Product.ProductNumber AS Number, 
	Product.ListPrice AS Price
FROM  Production.Product Product 
	INNER JOIN Production.ProductSubcategory Subcategory 
		ON Product.ProductSubcategoryID = Subcategory.ProductSubcategoryID 
	LEFT JOIN Production.ProductCategory Category 
		ON Subcategory.ProductCategoryID = Category.ProductCategoryID
WHERE Product.ListPrice > 0 
	AND Product.SellEndDate IS NULL
ORDER BY CategoryName, SubcategoryName
FOR XML RAW('Product');

-- Listing 2-5. Building XML with FOR XML AUTO for a single table.
SELECT Product.Name, 
	Product.ProductNumber AS Number, 
	Product.ListPrice AS Price
FROM  Production.Product  
WHERE Product.ListPrice > 0 
	AND Product.SellEndDate IS NULL
ORDER BY Product.Name
FOR XML AUTO;

-- Listing 2-7. Changing the element name by aliasing a table with FOR XML AUTO.
SELECT Product.Name, 
	Product.ProductNumber AS Number, 
	Product.ListPrice AS Price
FROM  Production.Product AS Product 
WHERE Product.ListPrice > 0 
	AND Product.SellEndDate IS NULL
ORDER BY Product.Name
FOR XML AUTO;

-- Listing 2-9. Using the OR XML AUTO clause to construct XML data with multiple joined tables.
SELECT Category.Name AS CategoryName, 
	Subcategory.Name AS SubcategoryName,
	Product.Name, 
	Product.ProductNumber AS Number, 
	Product.ListPrice AS Price,
	SellEndDate
FROM  Production.Product Product 
	INNER JOIN Production.ProductSubcategory Subcategory 
		ON Product.ProductSubcategoryID = Subcategory.ProductSubcategoryID 
	LEFT JOIN Production.ProductCategory Category 
		ON Subcategory.ProductCategoryID = Category.ProductCategoryID
WHERE Product.ListPrice > 0 
	AND Product.SellEndDate IS NULL
ORDER BY CategoryName, SubcategoryName
FOR XML AUTO;

-- Listing 2-10. FOR XML AUTO query with ELEMENTS directive.
SELECT Product.Name, 
	Product.ProductNumber AS Number, 
	Product.ListPrice AS Price
FROM  Production.Product AS Product 
WHERE Product.ListPrice > 0 
	AND Product.SellEndDate IS NULL
ORDER BY Product.Name
FOR XML AUTO, ELEMENTS;

-- Listing 2-12. Adding the ROOT directive to a FOR XML AUTO query.
SELECT Product.Name, 
	Product.ProductNumber AS Number, 
	Product.ListPrice AS Price
FROM  Production.Product AS Product 
WHERE Product.ListPrice > 0 
	AND Product.SellEndDate IS NULL
ORDER BY Product.Name
FOR XML AUTO, ELEMENTS, ROOT; 

-- Listing 2-14. Adding an XSINIL option to the FOR XML query.
SELECT Product.Name, 
	Product.ProductNumber AS Number, 
	Product.ListPrice AS Price,
	SellEndDate
FROM  Production.Product AS Product 
WHERE Product.ListPrice > 0
ORDER BY Product.Name
FOR XML AUTO, ELEMENTS XSINIL, ROOT('Products');

-- Listing 2-16. Failing query to retrieve binary data in XML format.
SELECT LargePhotoFileName, 
	LargePhoto
FROM  Production.ProductPhoto
FOR XML AUTO, ELEMENTS;  

-- Listing 2-17. Working query to retrieve binary data in XML format.
SELECT LargePhotoFileName, 
	LargePhoto, 
	ProductPhotoID
FROM  Production.ProductPhoto
FOR XML AUTO, ELEMENTS;  

-- Listing 2-19. Using the BINARY BASE64 directive of the FOR XML clause.
SELECT LargePhotoFileName,
	LargePhoto
FROM  Production.ProductPhoto
FOR XML AUTO, ELEMENTS, BINARY BASE64;

-- Listing 2-20. First attempt at creating hierarchical XML with a correlated subquery.
SELECT Category.Name AS CategoryName, 
	(
		SELECT Subcategory.Name AS SubcategoryName
		FROM Production.ProductSubcategory Subcategory 
		WHERE Subcategory.ProductCategoryID = Category.ProductCategoryID
		FOR XML AUTO
	) Subcategory
FROM  Production.ProductCategory Category 
FOR XML AUTO, ROOT('Categories');

-- Listing 2-21. Implementing the TYPE directive.
SELECT Category.Name AS CategoryName, 
	(
		SELECT Subcategory.Name AS SubcategoryName
		FROM Production.ProductSubcategory Subcategory 
		WHERE Subcategory.ProductCategoryID = Category.ProductCategoryID
		FOR XML AUTO, TYPE
	) Subcategory
FROM  Production.ProductCategory Category 
FOR XML AUTO, ELEMENTS, TYPE, ROOT('Categories');

-- Listing 2-22. Using EXPLICIT mode to control the format of your XML result.   
SELECT 1		AS Tag,
	0		AS Parent,
	Prod.Name	AS [Categories!1!Category!ELEMENT],
	NULL		AS [Subcategories!2!Subcategory!ELEMENT], 
	NULL 		AS [Product!3!ProductName!ELEMENT],
	NULL		AS [Product!3!Color!ELEMENTXSINIL], 
	NULL		AS [Product!3!Shelf], 
	NULL		AS [Product!3!Bin], 
	NULL		AS [Product!3!Quantity]
FROM Production.ProductCategory Prod
	UNION ALL
SELECT 2 AS Tag, 
	1 AS Parent,
	Category.Name,
	Subcategory.Name,
	NULL,
	NULL, 
	NULL, 
	NULL, 
	NULL
FROM Production.ProductCategory Category
INNER JOIN Production.ProductSubcategory Subcategory
	ON Category.ProductCategoryID = Subcategory.ProductCategoryID
	UNION ALL
SELECT 3  AS Tag, 
	2  AS Parent,
	ProductCategory.Name,
	Subcategory.Name,
	Product.Name, 
	Product.Color, 
	Inventory.Shelf, 
	Inventory.Bin, 
	Inventory.Quantity
FROM Production.Product Product
	INNER JOIN Production.ProductInventory Inventory
	ON Product.ProductID = Inventory.ProductID 
	INNER JOIN Production.ProductSubcategory Subcategory
	ON Product.ProductSubcategoryID = Subcategory.ProductSubcategoryID 
	INNER JOIN Production.ProductCategory 
	ON Subcategory.ProductCategoryID = Production.ProductCategory.ProductCategoryID
ORDER BY [Categories!1!Category!ELEMENT],
	[Subcategories!2!Subcategory!ELEMENT],
	[Product!3!ProductName!ELEMENT]
FOR XML EXPLICIT, ROOT('Products');

-- Listing 2-23. SQL query we would like to convert to XML format.
SELECT ProductCategory.Name Category,
	Subcategory.Name Subcategory,
	Product.Name ProductName, 
	Product.Color, 
	Inventory.Shelf, 
	Inventory.Bin, 
	Inventory.Quantity
FROM Production.Product Product
	INNER JOIN Production.ProductInventory Inventory
	ON Product.ProductID = Inventory.ProductID 
	INNER JOIN Production.ProductSubcategory Subcategory
	ON Product.ProductSubcategoryID = Subcategory.ProductSubcategoryID 
	INNER JOIN Production.ProductCategory 
	ON Subcategory.ProductCategoryID = Production.ProductCategory.ProductCategoryID
ORDER BY ProductCategory.Name, Subcategory.Name, Product.Name;

-- Listing 2-26. Generating custom XML generation with PATH mode. 
SELECT ProductCategory.Name AS "Category/CategoryName",
	Subcategory.Name AS "Category/Subcategory/SubcategoryName",
	Inventory.Shelf AS "Category/Subcategory/Product/ProductName/@Shelf", 
	Inventory.Bin AS "Category/Subcategory/Product/ProductName/@Bin", 
	Inventory.Quantity AS "Category/Subcategory/Product/ProductName/@Quantity"
	Product.Name AS "Category/Subcategory/Product/ProductName", 
	Product.Color AS "Category/Subcategory/Product/Color",
FROM Production.Product Product
	INNER JOIN Production.ProductInventory Inventory
	ON Product.ProductID = Inventory.ProductID 
	INNER JOIN Production.ProductSubcategory Subcategory
	ON Product.ProductSubcategoryID = Subcategory.ProductSubcategoryID 
INNER JOIN Production.ProductCategory 
	ON Subcategory.ProductCategoryID = Production.ProductCategory.ProductCategoryID
ORDER BY ProductCategory.Name, Subcategory.Name, Product.Name
FOR XML PATH('Categories'), ELEMENTS XSINIL, ROOT('Products');

-- Listing 2-27. Demonstrating XPath node tests.
SELECT ProductCategory.Name AS "Category/CategoryName",
	N'Sales started ' + convert(nvarchar(12), Product.SellStartDate, 101) AS "Category/comment()",
	N'The record for product number ' + Product.ProductNumber AS "processing-instruction(xml_file)",
	(
		SELECT DISTINCT Location.Name "text()", N', cost rate $',
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
	ON Subcategory.ProductCategoryID = Production.ProductCategory.ProductCategoryID
ORDER BY ProductCategory.Name, Subcategory.Name, Product.Name
FOR XML PATH('Categories'), ELEMENTS XSINIL, ROOT('Products');
