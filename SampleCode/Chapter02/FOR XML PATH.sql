
SELECT ProductCategory.Name AS "Category/CategoryName",
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

