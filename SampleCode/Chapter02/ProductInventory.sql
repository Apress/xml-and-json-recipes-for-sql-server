/*

USE AdventureWorks2012;  
GO  
SELECT  1 as Tag,  
        0 as Parent,  
        ProductModelID  as [ProductModel!1!ProdModelID],  
        Name            as [ProductModel!1!Name],  
        '<Summary>This is summary description</Summary>'     
            as [ProductModel!1!!CDATA] -- no attribute name so ELEMENT assumed  
FROM    Production.ProductModel  
WHERE   ProductModelID=19  
FOR XML EXPLICIT 

*/
--select distinct Name from Production.Location
SELECT 1			AS Tag,
	0			AS Parent,
	Name              AS [Categories!1!Category!ELEMENT],
	NULL              AS [Subcategories!2!Subcategory!ELEMENT], 
	NULL              AS [Product!3!ProductName!ELEMENT],
	NULL			  AS [Product!3!Color!ELEMENTXSINIL], 
	NULL			  AS [Product!3!Shelf], 
	NULL			  AS [Product!3!Bin], 
	NULL			  AS [Product!3!Quantity]
FROM Production.ProductCategory
UNION ALL
SELECT 2                 AS Tag, 
	1                 AS Parent,
	Category.Name,
	Subcategory.Name,
	NULL,
	NULL, 
	NULL, 
	NULL, 
	NULL
FROM     Production.ProductCategory Category
	INNER JOIN Production.ProductSubcategory Subcategory
	ON Category.ProductCategoryID = Subcategory.ProductCategoryID
UNION ALL
SELECT 3              AS Tag, 
	2                 AS Parent,
	ProductCategory.Name,
	Subcategory.Name,
	Product.Name AS ProductName, 
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
ORDER BY [Categories!1!Category!ELEMENT]
	,[Subcategories!2!Subcategory!ELEMENT]
	,[Product!3!ProductName!ELEMENT]
FOR XML EXPLICIT, ROOT('Products')
GO

