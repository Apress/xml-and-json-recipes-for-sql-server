--USE AdventureWorks;

-- Listing 6-1. Retriving the instances that contains the YearrlyIncome element. 
WITH XMLNAMESPACES
(
	DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey'
)
SELECT BusinessEntityID, 
	Demographics 
FROM Person.Person	
WHERE Demographics.exist('IndividualSurvey/YearlyIncome') = 1;

-- Sample 6-2 Showing the YearlyIncome element with currency as an attribute
DECLARE @survey XML = N'<?xml version = "1.0" encoding = "utf-16" ?>
<IndividualSurvey 
	xmlns="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey">
  <TotalPurchaseYTD currency = "$">-16.01</TotalPurchaseYTD>
  <DateFirstPurchase>2003-09-01Z</DateFirstPurchase>
  <BirthDate>1961-02-23Z</BirthDate>
  <MaritalStatus>M</MaritalStatus>
  <YearlyIncome currency = "$">25001-50000</YearlyIncome>
  <Gender>M</Gender>
  <TotalChildren>4</TotalChildren>
  <NumberChildrenAtHome>0</NumberChildrenAtHome>
  <Education>Graduate Degree</Education>
  <Occupation>Clerical</Occupation>
  <HomeOwnerFlag>1</HomeOwnerFlag>
  <NumberCarsOwned>0</NumberCarsOwned>
  <CommuteDistance>0-1 Miles</CommuteDistance>
</IndividualSurvey>';

-- Listing 6-2 Searching for an attribute @currency
WITH XMLNAMESPACES
(
	DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey'
)
SELECT @survey,
	CASE WHEN @survey.exist('IndividualSurvey/YearlyIncome/@currency') = 1 THEN N'IndividualSurvey/YearlyIncome/@currency attribute is present.'
		ELSE N'currency attribute is NOT present.'
		END AS hasCurrency;

-- Listing 6-3. Using XQuery to filtering XML instances by values.
WITH XMLNAMESPACES
(
	DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey'
)
SELECT BusinessEntityID, 
	Demographics 
FROM Person.Person	
WHERE Demographics.exist('IndividualSurvey[TotalPurchaseYTD > 9000]') = 1;

-- Listing 6-4 Comparing <Education> and <Occupation> elements position.
WITH XMLNAMESPACES
(
	DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey'
)
SELECT BusinessEntityID, 
	Demographics.value('(/IndividualSurvey/Education)[1] << (/IndividualSurvey/Occupation)[1]', 'nvarchar(20)') [Node Comparison]
FROM Person.Person	
WHERE BusinessEntityID = 2436;

-- Listing 6-6. Filtering with date types.
WITH XMLNAMESPACES
(
DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey'
)
SELECT BusinessEntityID, 
	Demographics 
FROM Person.Person	
WHERE Demographics.exist
('IndividualSurvey[DateFirstPurchase=xs:date("2002-06-28Z")]') = 1;

-- Listing 6-7. Inserting a new row via the stored procedure
WITH XMLNAMESPACES
(
N'http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/Resume' AS ns
)
SELECT 
	Info.value(N'(/ns:Resume/ns:Name/ns:Name.First)[1]', 'NVARCHAR(30)') AS FirstName,
	Info.value(N'(/ns:Resume/ns:Name/ns:Name.Last)[1]', 'NVARCHAR(30)') AS LastName,
	Info.value('fn:string(../../../../ns:Address[1]/ns:Addr.Location[1]/ns:Location[1]/ns:Loc.CountryRegion[1])', 'NVARCHAR(100)') AS Country,
	Info.value('fn:string(../ns:Tel.Type[1])', 'NVARCHAR(15)') AS PhoneType,
	Info.value('fn:string(../ns:Tel.AreaCode[1])', 'NVARCHAR(9)') AS AreaCode,
	Info.value('fn:string(.)', 'NVARCHAR(20)') AS CandidatePhone
FROM HumanResources.JobCandidate
	CROSS APPLY Resume.nodes('//ns:Tel.Number') AS Person(Info);

-- Listing 6-9 Setting a single value filter within the nodes() Method.
WITH XMLNAMESPACES
(
	DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey'
)
SELECT BusinessEntityID ,
	ref.value('TotalPurchaseYTD', 'MONEY') AS TotalPurchase,
	ref.value('DateFirstPurchase', 'DATE') AS DateFirstPurchase,
	ref.value('YearlyIncome', 'NVARCHAR(20)') AS YearlyIncome,
	ref.value('Occupation', 'NVARCHAR(15)') AS Occupation,
	ref.value('CommuteDistance', 'NVARCHAR(15)') AS CommuteDistance
FROM Person.Person CROSS APPLY 
      Demographics.nodes('IndividualSurvey[TotalPurchaseYTD > 9000]') AS dmg(ref);

-- Listing 6-10. Creating a stored procedure with sql:variable() function
CREATE PROCEDURE dbo.usp_DemographicsByYearlyIncome
	@YearlyIncome NVARCHAR(20)
AS
BEGIN		
	WITH XMLNAMESPACES
	(
		DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey'
	)
	SELECT BusinessEntityID ,
		ref.value('TotalPurchaseYTD', 'MONEY') AS TotalPurchase,
		ref.value('DateFirstPurchase', 'DATE') AS DateFirstPurchase,
		ref.value('YearlyIncome', 'NVARCHAR(20)') AS YearlyIncome,
		ref.value('Occupation', 'NVARCHAR(15)') AS Occupation,
		ref.value('CommuteDistance', 'NVARCHAR(15)') AS CommuteDistance
	FROM Person.Person	
		CROSS APPLY Demographics.nodes('IndividualSurvey[YearlyIncome=sql:variable("@YearlyIncome")]') AS dmg(ref);
END;
GO

-- Listing  6-11. Calling the usp_DemographicsByYearlyIncome stored procedure.
EXECUTE dbo.usp_DemographicsByYearlyIncome '0-25000';
GO

EXECUTE dbo.usp_DemographicsByYearlyIncome '25001-50000';
GO

EXECUTE dbo.usp_DemographicsByYearlyIncome '50001-75000';
GO

EXECUTE dbo.usp_DemographicsByYearlyIncome '75001-100000';
GO

EXECUTE dbo.usp_DemographicsByYearlyIncome 'greater than 100000';
GO

-- Listing 6-12. Sending a list of values to filter an XML instance.  
WITH XMLNAMESPACES
(
	DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey'
)
SELECT BusinessEntityID,
	ref.value('TotalPurchaseYTD', 'MONEY') AS TotalPurchase,
	ref.value('DateFirstPurchase', 'DATE') AS DateFirstPurchase,
	ref.value('YearlyIncome', 'NVARCHAR(20)') AS YearlyIncome,
	ref.value('Occupation', 'NVARCHAR(15)') AS Occupation,
	ref.value('CommuteDistance', 'NVARCHAR(15)') AS CommuteDistance
FROM Person.Person 
	CROSS APPLY Demographics.nodes('IndividualSurvey[Occupation=("Clerical","Manual", "Professional")]') AS dmg(ref);

-- Listing 6-13. Searching for the string "Manual" within the Occupation element.
WITH XMLNAMESPACES
(
	DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey'
)
SELECT BusinessEntityID ,
	Demographics,
	ref.value('TotalPurchaseYTD', 'MONEY') AS TotalPurchase,
	ref.value('DateFirstPurchase', 'DATE') AS DateFirstPurchase,
	ref.value('YearlyIncome', 'NVARCHAR(20)') AS YearlyIncome,
	ref.value('Occupation', 'NVARCHAR(15)') AS Occupation,
	ref.value('CommuteDistance', 'NVARCHAR(15)') AS CommuteDistance
FROM Person.Person 
	CROSS APPLY Demographics.nodes('IndividualSurvey[ ( fn:contains(Occupation[1], "Manual" ) ) ]') AS dmg(ref);

-- Listing 6-14. Filtering an XML instance using fn:contains() XQuery and T-SQL hybrid solution 
WITH XMLNAMESPACES
(
	DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey'
),
Subset AS
(
	SELECT BusinessEntityID,
		ref.value('TotalPurchaseYTD', 'MONEY') AS TotalPurchase,
		ref.value('DateFirstPurchase', 'DATE') AS DateFirstPurchase,
		ref.value('YearlyIncome', 'NVARCHAR(20)') AS YearlyIncome,
		ref.value('Occupation', 'NVARCHAR(15)') AS Occupation,
		ref.value('CommuteDistance', 'NVARCHAR(15)') AS CommuteDistance
	FROM Person.Person 
		CROSS APPLY Demographics.nodes('IndividualSurvey[ fn:contains(Occupation[1], "Manual" ) ]') AS dmg(ref)
)
SELECT BusinessEntityID,
	TotalPurchase,
	DateFirstPurchase,
	YearlyIncome,
	Occupation,
	CommuteDistance
FROM Subset
WHERE Occupation LIKE 'Manual%';

-- Listing 6-15. Implementing the value range filter.
WITH XMLNAMESPACES
(
DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey'
)
SELECT BusinessEntityID,
	ref.value('TotalPurchaseYTD', 'MONEY') TotalPurchase,
	ref.value('DateFirstPurchase', 'DATE') DateFirstPurchase,
	ref.value('YearlyIncome', 'NVARCHAR(20)') YearlyIncome,
	ref.value('Occupation', 'NVARCHAR(15)') Occupation,
	ref.value('CommuteDistance', 'NVARCHAR(15)') CommuteDistance
FROM Person.Person 
	CROSS APPLY Demographics.nodes('IndividualSurvey[ TotalPurchaseYTD >= 1000 and TotalPurchaseYTD <= 2000 ]') AS dmg(ref);

-- Listing 6-16. Implementing multiple filter condition.
WITH XMLNAMESPACES
(
	DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey'
)
SELECT BusinessEntityID,
	ref.value('TotalPurchaseYTD', 'MONEY') AS TotalPurchase,
	ref.value('DateFirstPurchase', 'DATE') AS DateFirstPurchase,
	ref.value('YearlyIncome', 'NVARCHAR(20)') AS YearlyIncome,
	ref.value('Occupation', 'NVARCHAR(15)') AS Occupation,
	ref.value('CommuteDistance', 'NVARCHAR(15)') AS CommuteDistance
FROM Person.Person 
CROSS APPLY Demographics.nodes('IndividualSurvey[ TotalPurchaseYTD >= 1001 
	and TotalPurchaseYTD < 1004 
	and CommuteDistance = "0-1 Miles"
	or DateFirstPurchase > xs:date("2004-07-30Z") ]'
) AS dmg(ref);

-- Listing 6-17. Demonstrating negative operators.
WITH XMLNAMESPACES
(
	DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey'
)
SELECT BusinessEntityID,
	ref.value('TotalPurchaseYTD[1]', 'MONEY') AS TotalPurchase,
	ref.value('DateFirstPurchase[1]', 'DATE') AS DateFirstPurchase,
	ref.value('YearlyIncome[1]', 'NVARCHAR(15)') AS YearlyIncome,
	ref.value('Occupation[1]', 'NVARCHAR(15)') AS Occupation,
	ref.value('CommuteDistance[1]', 'NVARCHAR(15)') AS CommuteDistance
FROM Person.Person 
	CROSS APPLY Demographics.nodes('IndividualSurvey[ YearlyIncome != "0-25000" and fn:not( Occupation = ( "Clerical","Manual","Professional" ) ) ]') AS dmg(ref);

-- Listing 6-18. Verifying the value existence.
WITH XMLNAMESPACES
(
	DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey'
)
SELECT BusinessEntityID,
	ref.value('TotalPurchaseYTD[1]', 'MONEY') AS TotalPurchase,
	ref.value('DateFirstPurchase[1]', 'DATE') AS DateFirstPurchase,
	ref.value('YearlyIncome[1]', 'NVARCHAR(15)') AS YearlyIncome,
	ref.value('Occupation[1]', 'NVARCHAR(15)') AS Occupation,
	ref.value('CommuteDistance[1]', 'NVARCHAR(15)') AS CommuteDistance
FROM person.Person 
	CROSS APPLY Demographics.nodes('IndividualSurvey[fn:not(fn:empty(Occupation)) 
and fn:not( Occupation = ( "Clerical", "Manual", "Professional" ) ) ]') AS dmg(ref);

-- Listing 6-19. Demonstrates an alternative to the fn:empty() function
WITH XMLNAMESPACES
(
	DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey'
)
SELECT BusinessEntityID,
	ref.value('TotalPurchaseYTD[1]', 'MONEY') AS TotalPurchase,
	ref.value('DateFirstPurchase[1]', 'DATE') AS DateFirstPurchase,
	ref.value('YearlyIncome[1]', 'NVARCHAR(15)') AS YearlyIncome,
	ref.value('Occupation[1]', 'NVARCHAR(15)') AS Occupation,
	ref.value('CommuteDistance[1]', 'NVARCHAR(15)') AS CommuteDistance
FROM Person.Person 
	CROSS APPLY Demographics.nodes
('IndividualSurvey[fn:not( Occupation = ("Clerical", "Manual", "Professional" ) ) ]') AS dmg(ref)
WHERE Demographics.exist('IndividualSurvey/Occupation') = 1;

-- Listing 6-21. Demonstrating execution differences.
SET STATISTICS TIME ON;

WITH XMLNAMESPACES
(
	DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey'
)
SELECT BusinessEntityID,
	ref.value('fn:string(TotalPurchaseYTD[1])', 'MONEY') AS TotalPurchase,
	ref.value('fn:string(DateFirstPurchase[1])', 'DATE') AS DateFirstPurchase,
	ref.value('fn:string(YearlyIncome[1])', 'NVARCHAR (20)') AS YearlyIncome,
	ref.value('fn:string(Occupation[1])', 'NVARCHAR(15)') AS Occupation,
	ref.value('fn:string(CommuteDistance[1])', 'NVARCHAR(15)') AS CommuteDistance
FROM Person.Person 
	CROSS APPLY Demographics.nodes('IndividualSurvey[Occupation="Manual"]') AS dmg(ref);

WITH XMLNAMESPACES
(
	DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey'
)
SELECT BusinessEntityID,
	ref.value('fn:string(TotalPurchaseYTD[1])', 'MONEY') AS TotalPurchase,
	ref.value('fn:string(DateFirstPurchase[1])', 'DATE') AS DateFirstPurchase,
	ref.value('fn:string(YearlyIncome[1])', 'NVARCHAR(20)') AS YearlyIncome,
	ref.value('fn:string(Occupation[1])', 'NVARCHAR(15)') AS Occupation,
	ref.value('fn:string(CommuteDistance[1])', 'NVARCHAR(15)') AS CommuteDistance
FROM Person.Person 
	CROSS APPLY Demographics.nodes('IndividualSurvey') AS dmg(ref)
WHERE ref.value('fn:string(Occupation[1])', 'NVARCHAR(15)') = 'Manual';

SET STATISTICS TIME OFF;

