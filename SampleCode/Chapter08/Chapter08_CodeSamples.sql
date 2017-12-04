USE [WideWorldImporters];

-- Listing 8-2 Showing 
SELECT TOP (2) CustomerName
	,PrimaryContact
	,AlternateContact
	,PhoneNumber
FROM WideWorldImporters.Website.Customers
FOR JSON AUTO;

-- Listing 8-4 Showing SQL with original tables name
SELECT db_name() as [Database],
	sys.schemas.name,
	sys.objects.name,
	sys.columns.name 
FROM sys.objects 
JOIN sys.schemas on sys.objects.schema_id = sys.schemas.schema_id
JOIN sys.columns ON sys.columns.object_id = sys.objects.object_id
JOIN ( SELECT TOP (1) o.object_id, count(c.name) [name] 
	FROM sys.columns c 
JOIN sys.objects o ON c.object_id = o.object_id WHERE type = 'u' 
	GROUP BY o.object_id HAVING COUNT(c.name) < 6
	 )  countCol
	ON countCol.object_id = sys.objects.object_id
WHERE type = 'u'
FOR JSON AUTO;

-- Listing 8-6 Showing SQL with the table aliases
SELECT db_name() as [Database],
	[Schema].name as [SchemaName],
	[Table].name  as [TableName], 
	[Column].name as [ColumnName] 
FROM sys.objects [Table] 
JOIN sys.schemas [Schema] on [Table].schema_id = [Schema].schema_id
JOIN sys.columns [Column] ON [Column].object_id = [Table].object_id
JOIN ( SELECT TOP (1) o.object_id, COUNT(c.name) [name] 
	FROM sys.columns c JOIN sys.objects o 
ON c.object_id = o.object_id where type = 'u' 
	GROUP BY o.object_id HAVING COUNT(c.name) < 6)  countCol
	ON countCol.object_id = [Table].object_id
WHERE type = 'u'
FOR JSON AUTO;

-- Listing 8-8 FOR JSON clause with INCLUDE_NULL_VALUES option
USE [WideWorldImporters];
SELECT TOP (1) [CustomerName]
	,[PrimaryContact]
	,[AlternateContact]
	,[PhoneNumber]
FROM [Website].[Customers] where [AlternateContact] IS NOT NULL
UNION ALL
SELECT TOP (1) [CustomerName]
	,[PrimaryContact]
	,[AlternateContact]
	,[PhoneNumber]
FROM [Website].[Customers] where [AlternateContact] IS NULL
FOR JSON AUTO, INCLUDE_NULL_VALUES;

-- Listing 8-10 Showing query and JSON output
SELECT TOP (1) [CustomerName]
	,[PrimaryContact]
	,[AlternateContact]
	,[PhoneNumber]
FROM [Website].[Customers] where [AlternateContact] IS NOT NULL
UNION ALL
SELECT TOP (1) [CustomerName]
	,[PrimaryContact]
	,[AlternateContact]
	,[PhoneNumber]
FROM [Website].[Customers] where [AlternateContact] IS NULL
FOR JSON AUTO;

-- Listing 8-11 Showing WITHOUT_ARRAY_WRAPPER option
SELECT TOP (2) [CustomerName]
	,[PrimaryContact]
	,[AlternateContact]
	,[PhoneNumber]
FROM [WideWorldImporters].[Website].[Customers]
FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER;

-- Listing 8-13 Showing ROOT option 
SELECT TOP (2) [CustomerName]
	,[PrimaryContact]
	,[AlternateContact]
	,[PhoneNumber]
FROM [WideWorldImporters].[Website].[Customers]
FOR JSON AUTO, ROOT('Customers');

-- Listing 8-16 Showing FOR JSON with PATH mode. 
USE WideWorldImporters;

SELECT db_name()     as 'Database',
	[Schema].name as 'Tables.SchemaName',
	[Table].name  as 'Tables.TableName', 
	[Column].name as 'Tables.Columns.ColumnName' 
FROM sys.objects [Table] 
	JOIN sys.schemas [Schema] on [Table].schema_id = [Schema].schema_id
	JOIN sys.columns [Column] ON [Column].object_id = [Table].object_id
WHERE type = 'u' and [Table].name = 'SupplierCategories'
FOR JSON PATH;

-- Listing 8-18 Showing query that generated a result for Figure 8-5.
SELECT db_name()     as 'Database',
	[Schema].name as 'Tables.SchemaName',
	[Table].name  as 'Tables.TableName', 
	[Column].name as 'Tables.Columns.ColumnName' 
FROM sys.objects [Table] 
	JOIN sys.schemas [Schema] on [Table].schema_id = [Schema].schema_id
	JOIN sys.columns [Column] ON [Column].object_id = [Table].object_id
WHERE type = 'u' and [Table].name = 'SupplierCategories'  

-- Listing 8-18 Showing query that generated a result for Figure 8-5.
SELECT db_name()     as 'Database',
	[Schema].name as 'Tables.SchemaName',
	[Table].name  as 'Tables.TableName', 
	[Column].name as 'Tables.Columns.ColumnName' 
FROM sys.objects [Table] 
	JOIN sys.schemas [Schema] on [Table].schema_id = [Schema].schema_id
	JOIN sys.columns [Column] ON [Column].object_id = [Table].object_id
WHERE type = 'u' and [Table].name = 'SupplierCategories'  

-- Listing 8-21 Encapsulating the column names within array 
SELECT db_name() as 'Database',
	[Schema].name as 'Tables.SchemaName',
	[Table].name as 'Tables.TableName', 
	(SELECT [Column].name as ColumnName FROM sys.columns [Column] 
		WHERE [Column].object_id = [Table].object_id FOR JSON AUTO
	) as 'Tables.Columns' 
FROM sys.objects [Table] 
	JOIN sys.schemas [Schema] on [Table].schema_id = [Schema].schema_id
WHERE type = 'u' and [Table].name = 'SupplierCategories'
FOR JSON PATH;

-- Listing 8-23 Showing JSON_QUERY() function with combination FOR JSON clause and PATH mode.

SELECT [CustomerName]
	,[PrimaryContact]
	,[AlternateContact]
	,[PhoneNumber]
	,JSON_QUERY(InvoiceDate) InvoiceDate
FROM CustomerInvoice
FOR JSON PATH;

-- Listing 8-25 Creating table CustomerInvoice with JSON data in column InvoiceDate. 
SELECT TOP (2) 
	[CustomerName]
	,[PrimaryContact]
	,[AlternateContact]
	,[PhoneNumber]
	,CAST((QUOTENAME('"InvoiceDate":' + QUOTENAME(CONVERT(varchar(20),InvoiceDate, 101) , '"'), '{')) AS VARCHAR(MAX)) InvoiceDate
INTO CustomerInvoice
FROM [Website].[Customers] Customers JOIN [Sales].[Invoices]  Invoices 
		ON Invoices.CustomerID = Customers.CustomerID;

-- Listing 8-26 Building JSON without JSON_QUERY()
SELECT CustomerName, PrimaryContact, AlternateContact, PhoneNumber, InvoiceDate
FROM CustomerInvoice
FOR JSON PATH;

-- Listing 8-28 Converting CLR values into a string.
SELECT TOP (2) Customers.CustomerName,
       People.FullName AS PrimaryContact,
       ap.FullName AS AlternateContact,
       Customers.PhoneNumber,
       Cities.CityName AS CityName,
       Customers.DeliveryLocation.ToString() AS DeliveryLocation
FROM Sales.Customers AS Customers
	JOIN [Application].People AS People
		ON Customers.PrimaryContactPersonID = People.PersonID
	JOIN [Application].People AS ap
		ON Customers.AlternateContactPersonID = ap.PersonID
	JOIN [Application].Cities AS Cities
		ON Customers.DeliveryCityID = Cities.CityID
FOR JSON PATH, ROOT('Customers');

-- Listing 8-32 Using CAST() function column with geography data type
SELECT TOP (2) Customers.CustomerName,
       People.FullName AS PrimaryContact,
       ap.FullName AS AlternateContact,
       Customers.PhoneNumber,
       Cities.CityName AS CityName,
       CAST(Customers.DeliveryLocation as nvarchar(1000)) AS DeliveryLocation
FROM Sales.Customers AS Customers
	JOIN Application.People AS People
		ON Customers.PrimaryContactPersonID = People.PersonID
	JOIN Application.People AS ap
		ON Customers.AlternateContactPersonID = ap.PersonID
	JOIN Application.Cities AS Cities
		ON Customers.DeliveryCityID = Cities.CityID
FOR JSON PATH, ROOT('Customers');
