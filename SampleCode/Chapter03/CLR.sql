--- Register the assembly

--C:\Windows\Microsoft.NET\Framework\v3.5\csc.exe /target:library /out:C:\SQLServerXML_JSON\Chapter03\CLR\ReadWriteXML.dll C:\SQLServerXML_JSON\Chapter03\CLR\XML_ETL.cs


USE master
GO
sp_configure 'clr enabled', 1
GO
RECONFIGURE
GO
EXEC sp_changedbowner 'sa'

ALTER DATABASE AdventureWorks2016 SET TRUSTWORTHY ON 

GO
CREATE ASSEMBLY ReadWriteXML
FROM 'C:\SQLServerXML_JSON\Chapter03\CLR\ReadWriteXML.dll'
WITH PERMISSION_SET = EXTERNAL_ACCESS
--UNSAFE
--EXTERNAL_ACCESS

--DROP FUNCTION [dbo].WriteXMLFile

--DROP FUNCTION [dbo].ReadXMLFile
--ALTER DATABASE [AdventureWorks2016] SET TRUSTWORTHY ON;
GO


CREATE FUNCTION [dbo].WriteXMLFile(
	@Content [nvarchar](MAX), 
	@DirPath [nvarchar](500), 
	@FileName [nvarchar](100), 
	@DateStamp [bit])
RETURNS [nvarchar](MAX) WITH EXECUTE AS owner
AS 
EXTERNAL NAME ReadWriteXML.XMLFileETL.WriteXMLFile
GO

CREATE FUNCTION [dbo].ReadXMLFile(@FilePath [nvarchar](500))
RETURNS [nvarchar](MAX) WITH EXECUTE AS OWNER
AS 
EXTERNAL NAME ReadWriteXML.XMLFileETL.ReadXMLFile
GO

SELECT cast(dbo.ReadXMLFile('C:\SQLServerXML_JSON\Chapter01\TypedXML.xml') as xml)


declare @x nvarchar(max) = N'<Category>
  <CategoryName>Accessories</CategoryName>
  <Subcategory>
    <SubcategoryName>Bike Racks</SubcategoryName>
    <Product>
      <Name>Hitch Rack - 4-Bike</Name>
      <Number>RA-H123</Number>
      <Price>120.0000</Price>
    </Product>
  </Subcategory>
  <Subcategory>
    <SubcategoryName>Bike Stands</SubcategoryName>
    <Product>
      <Name>All-Purpose Bike Stand</Name>
      <Number>ST-1401</Number>
      <Price>159.0000</Price>
    </Product>
  </Subcategory>
</Category>'
select  dbo.WriteXMLFile(@x, 'C:\SQLServerXML_JSON\WriteReadXMLFile', 'CatXML', 1)


