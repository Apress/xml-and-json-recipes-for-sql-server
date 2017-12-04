declare @xml xml

SELECT @xml = Instructions
FROM [Production].[ProductModel] 
WHERE ProductModelID = 7

;WITH XMLNAMESPACES('http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelManuInstructions' as df)
SELECT RTRIM(LTRIM(REPLACE(instruct.value('.', 'varchar(2000)'), CHAR(10), ''))) AS [Step Instruction]
	, instruct.value('../@LocationID', 'int') AS LaborStation
	, instruct.value('../@LaborHours', 'real') AS LaborHours
	, instruct.value('../@LotSize', 'int') AS LotSize
	, instruct.value('../@MachineHours', 'real') AS MachineHours
	, instruct.value('../@SetupHours', 'real') AS SetupHours
	, instruct.value('df:material[1]', 'varchar(100) ') AS Material
	, instruct.value('df:tool[1]', 'varchar(100) ') AS Tool
FROM @xml.nodes('df:root/df:Location/df:step') prod(instruct)
