--USE AdventureWorks;

-- Listing 7-3. Sampling XQuery with a filter
SELECT PersonID, Demographics 
FROM dbo.PersonXML
WHERE Demographics.exist('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey";
	IndividualSurvey[TotalPurchaseYTD > 9000]') = 1;

-- Listing 7-4 applies the index from the solution in Listing 7-1:

CREATE PRIMARY XML INDEX IX_PXML_PersonXML_Demographics 
ON dbo.PersonXML
(
	Demographics
);
GO

-- Listing 7-5. Querying the PersonXML table with a Primary XML index
SELECT PersonID, Demographics 
FROM dbo.PersonXML
WHERE Demographics.exist('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey";
	IndividualSurvey[TotalPurchaseYTD > 9000]') = 1;

-- Listing 7-6. Creating sample table with primary XML index
-- These settings are important when creating XML indexes
SET NUMERIC_ROUNDABORT OFF; 
SET ARITHABORT ON; 
SET ANSI_NULLS ON; 
SET ANSI_PADDING ON; 
SET ANSI_WARNINGS ON; 
SET CONCAT_NULL_YIELDS_NULL ON; 
SET QUOTED_IDENTIFIER ON; 
GO
-- Drop table SQL Server 2016 syntax
DROP TABLE IF EXISTS dbo.PersonXML

-- Create and populate a table called PersonXML
CREATE TABLE dbo.PersonXML
(
	PersonID INT NOT NULL,
	FirstName NVARCHAR(30) NOT NULL,
	MiddleName NVARCHAR(20)NULL,
	LastName NVARCHAR(30) NOT NULL,
	Demographics XML NULL,
	CONSTRAINT PK_PersonXML PRIMARY KEY CLUSTERED 
	(
		PersonID ASC
	)
);
GO

INSERT dbo.PersonXML
(
	PersonID, 
	FirstName, 
	MiddleName, 
	LastName, 
	Demographics
)
SELECT BusinessEntityID,
	FirstName,
	MiddleName,
	LastName,
	Demographics
FROM Person.Person;
GO

-- Now create the Primary XML index on the dbo.PersonXML table
CREATE PRIMARY XML INDEX IX_PXML_PersonXML_Demographics
ON dbo.PersonXML
(
	Demographics
);
GO

-- Listing 7-7. Creating a secondary path XML index. 
CREATE XML INDEX IX_XMLPATH_PersonXML_Demographics 
ON dbo.PersonXML
(
	Demographics
)
USING XML INDEX IX_PXML_PersonXML_Demographics
FOR PATH;

-- Listing 7-9. Showing a secondary path type XML index specifying the path and predicate.
SELECT PersonID, Demographics 
FROM dbo.PersonXML
WHERE Demographics.exist('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey";
/IndividualSurvey[TotalPurchaseYTD > 9000]') = 1;

-- Listing 7-11. Creating a secondary value type index.
CREATE XML INDEX IX_XMLVALUE_PersonXML_Demographics
ON dbo.PersonXML
(
	Demographics
)
USING XML INDEX IX_PXML_PersonXML_Demographics
FOR VALUE;

-- Listing 7-12. Showing XQuery benefits from utilizing a secondary value XML index
SELECT PersonID,
	ref.value('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey";
		TotalPurchaseYTD[1]', 'money') TotalPurchase,
	ref.value('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey";
		DateFirstPurchase[1]', 'date') DateFirstPurchase,
	ref.value('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey";
		YearlyIncome[1]', 'varchar(20)') YearlyIncome,
	ref.value('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey";
		Occupation[1]', 'varchar(15)') Occupation,
	ref.value('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey";
		CommuteDistance[1]', 'varchar(15)') CommuteDistance
FROM PersonXML 
CROSS APPLY Demographics.nodes('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey";
	  /*[YearlyIncome="50001-75000"]') dmg(ref);
GO

-- Listing 7-14. Creating a secondary property XML index
CREATE XML INDEX IX_XMLPROPERTY_PersonXML_Demographics
ON dbo.PersonXML
(
	Demographics
)
USING XML INDEX IX_PXML_PersonXML_Demographics
FOR PROPERTY;

-- Listing 7-15. Showing the benefits of using XQuery when a PROPERTY index is present.
SELECT PersonID,
	ref.value('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey";
		TotalPurchaseYTD[1]', 'money') TotalPurchase,
	ref.value('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey";
		DateFirstPurchase[1]', 'date') DateFirstPurchase,
	ref.value('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey";
		YearlyIncome[1]', 'varchar(20)') YearlyIncome,
	ref.value('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey";
		Occupation[1]', 'varchar(15)') Occupation,
	ref.value('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey";
		CommuteDistance[1]', 'varchar(15)') CommuteDistance
FROM PersonXML 
CROSS APPLY Demographics.nodes('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey";
	IndividualSurvey[TotalPurchaseYTD > 1000 and TotalPurchaseYTD < 1005 
		and CommuteDistance = "0-1 Miles"]') dmg(ref);
GO

-- Create the selective XML index
CREATE SELECTIVE XML INDEX IX_SELECTIVE_XML_ProductXML
ON dbo.ProductXML
(
	ProductDetails
)
FOR 
(
    Quantity = '/Products/Categories/Category/Subcategory/Product/ProductLocation/Quantity',
    ProductName = '/Products/Categories/Category/Subcategory/Product/ProductName' 
);
GO

-- Listing 7-17. Showing the demo query
SET STATISTICS TIME ON;

SELECT ProductID, Name, ProductNumber, ProductDetails
FROM dbo.ProductXML
WHERE ProductDetails.exist('Products/Categories/Category/Subcategory/Product/ProductLocation/Quantity[.="622"]') = 1;

SET STATISTICS TIME OFF; 

-- Listing 7-18. Demo query run after selective XML index is created
SET STATISTICS TIME ON;

SELECT ProductID, Name, ProductNumber, ProductDetails
FROM dbo.ProductXML
WHERE ProductDetails.exist('Products/Categories/Category/Subcategory/Product/ProductLocation/Quantity[.="622"]') = 1;

-- Listing 7-19. SQL code for searching for a job candidate 
WITH XMLNAMESPACES('http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/Resume' as ns)
SELECT JobCandidateID, Resume
FROM HumanResources.JobCandidate
WHERE Resume.exist('/ns:Resume/ns:Name/ns:Name.First[.="Stephen"]') = 1

-- Listing 7-20. The CREATE SELECTIVE XML INDEX statement on a column with XMLNAMESPACE
CREATE SELECTIVE XML INDEX IX_SELECTIVE_XML_HumanResources_JobCandidate
ON [HumanResources].[JobCandidate]
(
	[Resume]
)
WITH XMLNAMESPACES
(
	DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/Resume'
)
FOR 
(
   	LastName = '/Resume/Name/Name.Last'
,FirstName = '/Resume/Name/Name.First'
);

-- Listing 7-21. Testing different hints for the selective XML index.
CREATE SELECTIVE XML INDEX IX_SELECTIVE_XML_ProductXML_Hint_Sample
ON dbo.ProductXML
(
	ProductDetails
)
FOR 
(
	SubcategoryName = '/Products/Categories/Category/Subcategory/SubcategoryName' AS XQUERY 'node()',
	Shelf = '/Products/Categories/Category/Subcategory/Product/ProductLocation/Shelf',
	Bin = '/Products/Categories/Category/Subcategory/Product/ProductLocation/Bin' AS XQUERY 'xs:double' SINGLETON,
	ProductName = '/Products/Categories/Category/Subcategory/Product/ProductName' AS SQL nvarchar(40),
	CategoryName = '/Products/Categories/Category/CategoryName' AS XQUERY 'xs:string' MAXLENGTH(35)
);

-- Listing 7-22. Testing different hints for the selective XML index.
CREATE SELECTIVE XML INDEX IX_SELECTIVE_XML_ProductXML_Hint_Sample
ON dbo.ProductXML
(
	ProductDetails
)
FOR 
(
	SubcategoryName = '/Products/Categories/Category/Subcategory/SubcategoryName' AS XQUERY 'node()',
	Shelf = '/Products/Categories/Category/Subcategory/Product/ProductLocation/Shelf',
	Bin = '/Products/Categories/Category/Subcategory/Product/ProductLocation/Bin' AS XQUERY 'xs:double' SINGLETON,
	ProductName = '/Products/Categories/Category/Subcategory/Product/ProductName' AS SQL nvarchar(40),
	CategoryName = '/Products/Categories/Category/CategoryName' AS XQUERY 'xs:string' MAXLENGTH(35)
);

-- Listing 7-23. Demonstrating how to create a secondary selective XML index
CREATE XML INDEX IX_SELECTIVE_SECONDARY_XML_HumanResources_JobCandidate 
ON HumanResources.JobCandidate
(
	Resume
)
USING XML INDEX IX_SELECTIVE_XML_HumanResources_JobCandidate 
FOR (LastName);

-- Listing 7-24. Create demonstration table with selective XML index
-- These settings are important when creating a table with XML columns and XML indexes
SET NUMERIC_ROUNDABORT OFF; 
SET ARITHABORT ON; 
SET ANSI_NULLS ON; 
SET ANSI_PADDING ON; 
SET ANSI_WARNINGS ON; 
SET CONCAT_NULL_YIELDS_NULL ON; 
SET QUOTED_IDENTIFIER ON; 
GO
-- Drop table SQL Server 2016 syntax
DROP TABLE IF EXISTS dbo.PersonXML

-- Create demo table with an XML column
CREATE TABLE dbo.ProductXML
(
	ProductID INT NOT NULL,
	Name NVARCHAR(50) NOT NULL,
	ProductNumber NVARCHAR(25) NOT NULL,
	ProductDetails XML NULL
	CONSTRAINT PK_ProductXML_ProductID PRIMARY KEY CLUSTERED 
	(
		ProductID ASC
	)
);
GO

-- Populate table with sample XML data
INSERT INTO dbo.ProductXML
(
	ProductID,
	Name,
	ProductNumber,
	ProductDetails
)
SELECT Product2.ProductId,
	Product2.Name,
	Product2.ProductNumber,
	(
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
		WHERE Product.ProductID = Product2.ProductId
		ORDER BY ProductCategory.Name, Subcategory.Name, Product.Name
		FOR XML PATH('Categories'), ROOT('Products'), ELEMENTS, TYPE
	)
FROM Production.Product Product2;
GO

-- Listing 7-16. Creating a selective XML index. 
-- These settings are important when creating a table with XML columns and XML indexes
SET NUMERIC_ROUNDABORT OFF; 
SET ARITHABORT ON; 
SET ANSI_NULLS ON; 
SET ANSI_PADDING ON; 
SET ANSI_WARNINGS ON; 
SET CONCAT_NULL_YIELDS_NULL ON; 
SET QUOTED_IDENTIFIER ON; 
GO
-- Drop table SQL Server 2016 syntax
DROP TABLE IF EXISTS dbo.ProductXML

-- Create demo table with an XML column
CREATE TABLE dbo.ProductXML
(
	ProductID INT NOT NULL,
	Name NVARCHAR(50) NOT NULL,
	ProductNumber NVARCHAR(25) NOT NULL,
	ProductDetails XML NULL
	CONSTRAINT PK_ProductXML_ProductID PRIMARY KEY CLUSTERED 
	(
		ProductID ASC
	)
);
GO

-- Populate table with sample XML data
INSERT INTO dbo.ProductXML
(
	ProductID,
	Name,
	ProductNumber,
	ProductDetails
)
SELECT Product2.ProductId,
	Product2.Name,
	Product2.ProductNumber,
	(
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
		WHERE Product.ProductID = Product2.ProductId
		ORDER BY ProductCategory.Name, Subcategory.Name, Product.Name
		FOR XML PATH('Categories'), ROOT('Products'), ELEMENTS, TYPE
	)
FROM Production.Product Product2;
GO

-- Create the selective XML index
CREATE SELECTIVE XML INDEX IX_SELECTIVE_XML_ProductXML
ON dbo.ProductXML
(
	ProductDetails
)
FOR 
(
    Quantity = '/Products/Categories/Category/Subcategory/Product/ProductLocation/Quantity',
    ProductName = '/Products/Categories/Category/Subcategory/Product/ProductName' 
);
GO


-- Listing 7-25. Altering selective XML index
ALTER INDEX IX_SELECTIVE_XML_ProductXML
ON dbo.ProductXML
FOR   
(  
    ADD CategoryName = '/Products/Categories/Category/CategoryName',  
    REMOVE Quantity
);

-- Listing 7-26. Altering selective index with separate ALTER INDEX statements

ALTER INDEX IX_SELECTIVE_XML_ProductXML  
ON ProductXML
FOR   
(  
	REMOVE Quantity  
);
GO

-- Listing 7-27. Dropping a selective XML index
DROP INDEX IX_SELECTIVE_XML_ProductXML
ON dbo.ProductXML;
