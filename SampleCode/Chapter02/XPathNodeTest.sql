

SELECT ProductCategory.Name AS "Category/CategoryName",
	'Sales started ' + convert(varchar(12), Product.SellStartDate, 101) AS "comment()",
	'The record for product number ' + Product.ProductNumber AS "processing-instruction(xml_file)",
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



--select *  FROM Production.Product Product
/*

SELECT DISTINCT Location.Name "text()", 
	', cost rate $',
	Location.CostRate "text()"
FROM Production.ProductInventory Inventory 
	INNER JOIN Production.Location Location
		ON Inventory.LocationID = Location.LocationID 
WHERE /*Product.ProductID = */Inventory.ProductID  = 1
FOR XML PATH('LocationName'), TYPE




SELECT Product.ProductID,Location.Name AS LocationName, 
	Location.CostRate, 
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

*/