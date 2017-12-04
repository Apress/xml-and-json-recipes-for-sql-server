
CREATE XML SCHEMA COLLECTION TypedXML_VisualStudio AS 
N'<?xml version="1.0" encoding="utf-16"?>
<xs:schema attributeFormDefault="unqualified" elementFormDefault="qualified" xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <xs:element name="Category">
    <xs:complexType>
      <xs:sequence>
        <xs:element name="CategoryName" type="xs:string" />
        <xs:element maxOccurs="unbounded" name="Subcategory">
          <xs:complexType>
            <xs:sequence>
              <xs:element name="SubcategoryName" type="xs:string" />
              <xs:element name="Product">
                <xs:complexType>
                  <xs:sequence>
                    <xs:element name="Name" type="xs:string" />
                    <xs:element name="Number" type="xs:string" />
                    <xs:element name="Price" type="xs:decimal" />
                  </xs:sequence>
                </xs:complexType>
              </xs:element>
            </xs:sequence>
          </xs:complexType>
        </xs:element>
      </xs:sequence>
    </xs:complexType>
  </xs:element>
</xs:schema>'
GO

CREATE TABLE TypedXML_VS
(
	TypedXML_ID int IDENTITY PRIMARY KEY,
	TypedXMLData XML(TypedXML_VisualStudio)
)

-- DROP XML SCHEMA COLLECTION TypedXML_SSMS 
CREATE XML SCHEMA COLLECTION TypedXML_SSMS AS 
 N'<xsd:schema xmlns:schema="ProductSchema" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:sqltypes="http://schemas.microsoft.com/sqlserver/2004/sqltypes" elementFormDefault="qualified">
  <xsd:import namespace="http://schemas.microsoft.com/sqlserver/2004/sqltypes" schemaLocation="http://schemas.microsoft.com/sqlserver/2004/sqltypes/sqltypes.xsd" />
  <xsd:element name="Category">
    <xsd:complexType>
      <xsd:sequence>
        <xsd:element name="CategoryName" minOccurs="0">
          <xsd:simpleType sqltypes:sqlTypeAlias="[AdventureWorks2012].[dbo].[Name]">
            <xsd:restriction base="sqltypes:nvarchar" sqltypes:localeId="1033" sqltypes:sqlCompareOptions="IgnoreCase IgnoreKanaType IgnoreWidth" sqltypes:sqlSortId="52">
              <xsd:maxLength value="50" />
            </xsd:restriction>
          </xsd:simpleType>
        </xsd:element>
        <xsd:element ref="Subcategory" minOccurs="0" maxOccurs="unbounded" />
      </xsd:sequence>
    </xsd:complexType>
  </xsd:element>
  <xsd:element name="Subcategory">
    <xsd:complexType>
      <xsd:sequence>
        <xsd:element name="SubcategoryName">
          <xsd:simpleType sqltypes:sqlTypeAlias="[AdventureWorks2012].[dbo].[Name]">
            <xsd:restriction base="sqltypes:nvarchar" sqltypes:localeId="1033" sqltypes:sqlCompareOptions="IgnoreCase IgnoreKanaType IgnoreWidth" sqltypes:sqlSortId="52">
              <xsd:maxLength value="50" />
            </xsd:restriction>
          </xsd:simpleType>
        </xsd:element>
        <xsd:element ref="Product" minOccurs="0" maxOccurs="unbounded" />
      </xsd:sequence>
    </xsd:complexType>
  </xsd:element>
  <xsd:element name="Product">
    <xsd:complexType>
      <xsd:sequence>
        <xsd:element name="Name">
          <xsd:simpleType sqltypes:sqlTypeAlias="[AdventureWorks2012].[dbo].[Name]">
            <xsd:restriction base="sqltypes:nvarchar" sqltypes:localeId="1033" sqltypes:sqlCompareOptions="IgnoreCase IgnoreKanaType IgnoreWidth" sqltypes:sqlSortId="52">
              <xsd:maxLength value="50" />
            </xsd:restriction>
          </xsd:simpleType>
        </xsd:element>
        <xsd:element name="Number">
          <xsd:simpleType>
            <xsd:restriction base="sqltypes:nvarchar" sqltypes:localeId="1033" sqltypes:sqlCompareOptions="IgnoreCase IgnoreKanaType IgnoreWidth" sqltypes:sqlSortId="52">
              <xsd:maxLength value="25" />
            </xsd:restriction>
          </xsd:simpleType>
        </xsd:element>
        <xsd:element name="Price" type="sqltypes:money" />
      </xsd:sequence>
    </xsd:complexType>
  </xsd:element>
</xsd:schema>'
GO
-- DROP TABLE TypedXML_SSMS
-- ALTER TABLE TypedXML_SSMS ALTER COLUMN TypedXMLData XML
-- ALTER TABLE TypedXML_SSMS ALTER COLUMN TypedXMLData XML(TypedXML_SSMS)
CREATE TABLE TypedXML_SSMS
(
	TypedXML_ID int IDENTITY PRIMARY KEY,
	TypedXMLData XML (TypedXML_SSMS)
)
GO

declare @doc XML = '<Category>
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

INSERT TypedXML_VS
SELECT @doc

INSERT TypedXML_SSMS
SELECT @doc

