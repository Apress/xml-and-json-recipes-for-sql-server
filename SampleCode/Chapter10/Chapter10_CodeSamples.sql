USE [WideWorldImporters];

-- Listing 10-1 Adding a new key-value pair to a JSON document.
SELECT CustomerName
	, PrimaryContact
	, AlternateContact
	, PhoneNumber
	, InvoiceDate
	, JSON_MODIFY(InvoiceDate,'$.SentBy', 'John Smith') NewInvoice
FROM [dbo].[CustomerInvoice];

-- Listing 10-2 Modifying a JSON document.
SELECT CustomFields
,JSON_MODIFY(CustomFields,'$.Title', 'Manager') NewCustomFields
FROM [Application].[People]
WHERE FullName = 'Hudson Onslow';

-- Listing 10-3 Deleting key "Title" with value. 
SELECT CustomFields
,JSON_MODIFY(CustomFields,'$.Title', NULL) NewCustomFields
FROM [Application].[People]
WHERE FullName = 'Hudson Onslow';

-- Listing 10-4 Deleting an array.  
declare @j as nvarchar(MAX) = 
N'{
  "OtherLanguages": [
    "Polish",
    "Chinese",
    "Japanese"
  ],
  "HireDate": "2008-04-19T00:00:00",
  "Title": "Team Member",
  "PrimarySalesTerritory": "Plains",
  "CommissionRate": "0.98"
}';

SELECT JSON_MODIFY(@j,'$.OtherLanguages', NULL) DeletedOtherLanguages;

-- Listing 10-5 Deleting object "table" from JSON document.
declare @j nvarchar(MAX) = 
N'{
  "theme": "humanity",
  "dateFormat": "dd/mm/yy",
  "timeZone": "PST",
  "table": {
    "pagingType": "full",
    "pageLength": 50
  },
  "favoritesOnDashboard": true
}';
SELECT JSON_MODIFY(@j,'$.table', NULL) Delete_table;

-- Listing 10-6 Appending Greek language to a JSON array. 
SELECT CustomFields
,JSON_MODIFY(CustomFields,'append $.OtherLanguages', 'Greek') AS AppendOtherLanguagesArray
FROM [Application].[People]
WHERE FullName = 'Isabella Rupp';

-- Listing 10-8 Demonstrating multiple JSON_MODIFY() function calls
SELECT CustomFields
,JSON_MODIFY(
	JSON_MODIFY(
		JSON_MODIFY(CustomFields,'append $.OtherLanguages', 'Greek')
			, '$.Title', 'Manager')
				,'$.CommissionRate', '1.19') AS Multi_Changes
FROM [Application].[People]
WHERE FullName = 'Isabella Rupp';

-- Listing 10-9 Renaming the OtherLanguages array.
SELECT 
	JSON_MODIFY(
		JSON_MODIFY(CustomFields,'$.SpokenLanguages', JSON_QUERY(JSON_QUERY(CustomFields, '$.OtherLanguages')))
			, '$.OtherLanguages', NULL) Rename_OtherLanguages_Array
FROM [Application].[People]
WHERE FullName = 'Isabella Rupp';

-- Listing 10-10 Replacing a JSON array.  
SELECT CustomFields, JSON_MODIFY(CustomFields, '$.OtherLanguages', 
		JSON_QUERY('["Dutch","Latvian","Lithuanian"]')) OtherLanguages
FROM [Application].[People] 
WHERE FullName = 'Isabella Rupp';

-- Listing 10-11 Replacing a JSON object. 
SELECT [UserPreferences], 
JSON_MODIFY([UserPreferences], '$.table', 
JSON_QUERY('{"pagingType":"full","pageLength":25,"pageScope":"private"}')   ) AS ModifiedUserPreferences
FROM [Application].[People]
WHERE FullName = 'Isabella Rupp'; 

-- Listing 10-12 Demonstrating the delete and re-insert query.
SELECT CustomFields, 
	JSON_MODIFY(
		JSON_MODIFY(CustomFields, '$.OtherLanguages', NULL), '$.OtherLanguages', JSON_QUERY('["Dutch","Latvian","Lithuanian"]')) OtherLanguages
FROM [Application].[People] 
WHERE FullName = 'Isabella Rupp';

-- 