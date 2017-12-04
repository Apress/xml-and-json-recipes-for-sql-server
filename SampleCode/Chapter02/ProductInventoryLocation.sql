use [AdventureWorks2012]
GO

SELECT Location.Name AS LocationName, 
	Location.CostRate,
	ProductCategory.Name AS Category, 
	Subcategory.Name AS Subcategory, 
	Product.Name AS ProductName, 
	Product.Color, 
	Inventory.Shelf, 
	Inventory.Bin, 
    Inventory.Quantity
FROM Production.Product Product
	INNER JOIN Production.ProductInventory Inventory
		ON Product.ProductID = Inventory.ProductID 
	INNER JOIN Production.Location Location
		ON Inventory.LocationID = Location.LocationID 
	INNER JOIN Production.ProductSubcategory Subcategory
		ON Product.ProductSubcategoryID = Subcategory.ProductSubcategoryID 
	INNER JOIN Production.ProductCategory 
		ON Subcategory.ProductCategoryID = Production.ProductCategory.ProductCategoryID
ORDER BY LocationName, Category, 
		Subcategory, 
		ProductName
		
FOR XML AUTO
GO
--select distinct Name from Production.Location
SELECT 1			AS Tag,
	NULL			AS Parent,
	Location.Name	AS [Location!1!Name!ELEMENT], 
	Location.CostRate AS [Location!1!CostRate], 
	NULL              AS [Category.Name!2!Category!ELEMENT],
	NULL              AS [Subcategory!3!Subcategory!ELEMENT], 
	NULL              AS [Product!4!ProductName!ELEMENT],
	NULL			  AS [Product!4!Color!ELEMENTXSINIL], 
	NULL			  AS [Product!4!Shelf], 
	NULL			  AS [Product!4!Bin], 
	NULL			  AS [Product!4!Quantity]
FROM Production.Location Location
UNION ALL
SELECT 2                 AS Tag, 
       1                 AS Parent,

FOR XML EXPLICIT
GO

/*
SELECT 1                    as Tag, 
       NULL                 as Parent,
       Customers.CustomerID as [Customer!1!CustomerID!ELEMENT],
       NULL                 as [Order!2!OrderID!element],
       NULL                 as [Order!2!CustomerID!idref], 
       NULL                 as [Order!2!OrderDate]
FROM [Northwind].dbo.Customers
UNION ALL
SELECT 2, 
       1,
       Customers.CustomerID,
       Orders.OrderID, Orders.CustomerID,
       Orders.OrderDate
FROM Customers JOIN Orders ON Customers.CustomerID = Orders.CustomerID
ORDER BY [Customer!1!CustomerID!ELEMENT], [Order!2!OrderID!element]
FOR XML EXPLICIT, ROOT('Orders')
*/