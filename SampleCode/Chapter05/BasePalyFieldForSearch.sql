;with XMLNAMESPACES(default 'http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey')
SELECT BusinessEntityID,FirstName, LastName,
	Demographics.query('IndividualSurvey[HomeOwnerFlag="1"]')
	,c.value('TotalPurchaseYTD[1]', 'decimal(8,1)') TotalPurchaseYTD
	,c.value('DateFirstPurchase[1]', 'date')
	,c.value('BirthDate[1]', 'date') BirthDate
  ,c.value('MaritalStatus', 'char(1)') MaritalStatus
  ,c.value('YearlyIncome[1]', 'varchar(20)') YearlyIncome
  ,c.value('Gender', 'char(1)') Gender
  ,c.value('TotalChildren[1]', 'int') TotalChildren
  ,c.value('NumberChildrenAtHome[1]', 'int') NumberChildrenAtHome
  ,c.value('Education[1]', 'varchar(200)') Education
  ,c.value('Occupation[1]', 'varchar(100)') Occupation
  ,c.value('HomeOwnerFlag[1]', 'bit') HomeOwnerFlag
  ,c.value('NumberCarsOwned[1]', 'tinyint') NumberCarsOwned
  ,c.value('CommuteDistance[1]', 'varchar(20)') CommuteDistance
FROM Person.Person
	cross apply Demographics.nodes('IndividualSurvey') t(c)