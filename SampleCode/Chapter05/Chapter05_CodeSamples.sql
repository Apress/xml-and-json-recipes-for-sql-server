--USE AdventureWorks;

-- Listing 5-1. Simple XML data.
/*
<Root>
  <ProductDescription ProductID="1" ProductName="Road Bike">
    <Features />
  </ProductDescription>
</Root>
*/

-- Listing 5-2. Inserting the first child element for the Features element.
DECLARE @XMLDoc xml;       
SET @XMLDoc = 
'<Root>       
    <ProductDescription ProductID="1" ProductName="Road Bike">       
        <Features>       
        </Features>       
    </ProductDescription>       
</Root>';

SET @XMLDoc.modify('insert <Maintenance>3 year parts and labor extended maintenance is available</Maintenance> into (/Root/ProductDescription/Features)[1]');
SELECT @XMLDoc;
GO

-- Listing 5-3. Declaring an XML namespace within the modify() method. 
DECLARE @XMLDoc xml;       
SET @XMLDoc = 
'<Root xmlns="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelManuInstructions">       
    <ProductDescription ProductID="1" ProductName="Road Bike">       
        <Features>       
        </Features>       
    </ProductDescription>       
</Root>';

SET @XMLDoc.modify('declare namespace ns="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelManuInstructions";
insert <ns:Maintenance>3 year parts and labor extended maintenance is available</ns:Maintenance> into (/ns:Root/ns:ProductDescription/ns:Features)[1]');
SELECT @XMLDoc;
GO

-- Listing 5-5. Using WITH XMLNAMESPACES to declare a default XML namespace.
DECLARE @XMLDoc xml;  
WITH XMLNAMESPACES(default 'http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelManuInstructions')     
SELECT @XMLDoc = 
'<Root>       
    <ProductDescription ProductID="1" ProductName="Road Bike">       
        <Features>       
        </Features>       
    </ProductDescription>       
</Root>';

SET @XMLDoc.modify('insert <Maintenance>3 year parts and labor extended maintenance is available</Maintenance> 
	into (/Root/ProductDescription/Features)[1]');
SELECT @XMLDoc;
GO

-- Listing 5-6. Inserting ProductModel attribute into the Maintenance element.
DECLARE @XMLDoc xml;       
SET @XMLDoc = 
'<Root>
  <ProductDescription ProductID="1" ProductName="Road Bike">
    <Features>
      <Maintenance>3 year parts and labor extended maintenance is available</Maintenance>
    </Features>
  </ProductDescription>
</Root>';

SET @XMLDoc.modify('insert attribute ProductModel {"Mountain-100"} into (/Root/ProductDescription/Features/Maintenance)[1]');

SELECT @XMLDoc; 
GO

-- Listing 5-7. Inserting multiple attributes into the Maintenance element.
DECLARE @XMLDoc xml;       
SET @XMLDoc = 
'<Root>
  <ProductDescription ProductID="1" ProductName="Road Bike">
    <Features>
      <Maintenance>3 year parts and labor extended maintenance is available</Maintenance>
    </Features>
  </ProductDescription>
</Root>';

SET @XMLDoc.modify('insert 
(
	attribute ProductModel {"Mountain-100"},
	attribute LaborType {"Manual"}
) into (/Root/ProductDescription/Features/Maintenance)[1]');

SELECT @XMLDoc; 
GO

-- Listing 5-8. Wrapping the attribute insert in an if-then-else condition.
DECLARE @XMLDoc xml;       
SET @XMLDoc = 
'<Root>
  <ProductDescription ProductID="1" ProductName="Road Bike">
    <Features>
      <Maintenance>3 year parts and labor extended maintenance is available</Maintenance>
    </Features>
  </ProductDescription>
</Root>';

SET @XMLDoc.modify('insert  
if (/Root/ProductDescription[@ProductID=1])  
	then attribute ProductModel {"Road-150"} 
	else (attribute ProductModel {"Mountain-100"} )  
into (/Root/ProductDescription/Features/Maintenance)[1]');

SELECT @XMLDoc;
GO

-- Listing 5-9. Demonstrating as first, as last, after, and before keywords to arrange the child elements under the parent element Features. 
DECLARE @XMLDoc xml;       
SET @XMLDoc = 
'<Root>
  <ProductDescription ProductID="1" ProductName="Road Bike">
    <Features>
    </Features>
  </ProductDescription>
</Root>';

SET @XMLDoc.modify('insert <Warranty>1 year parts and labor</Warranty> 
	as first  into (/Root/ProductDescription/Features)[1]');

SET @XMLDoc.modify('insert <Material>Aluminium</Material> 
	as last into (/Root/ProductDescription/Features)[1]');

SET @XMLDoc.modify('insert <BikeFrame>Strong long lasting</BikeFrame> 
	after (/Root/ProductDescription/Features/Material)[1]')

SET @XMLDoc.modify('insert <Color>Silver</Color> 
	before (/Root/ProductDescription/Features/BikeFrame)[1]')

SELECT @XMLDoc;

-- Listing 5-10. Inserting multiple sibling elements into an XML instance.
DECLARE @XMLDoc xml;       
SET @XMLDoc = 
'<Root>
  <ProductDescription ProductID="1" ProductName="Road Bike">
    <Features>
    </Features>
  </ProductDescription>
</Root>';

DECLARE @newElements xml;  
SET @newElements = 
'<Warranty>1 year parts and labor</Warranty>
<Material>Aluminium</Material>
<Color>Silver</Color>
<BikeFrame>Strong long lasting</BikeFrame>';           

SET @XMLDoc.modify('insert 
	sql:variable("@newElements")             
into (/Root/ProductDescription/Features)[1]')   
          
SELECT @XMLDoc;

-- Listing 5-11. Updating the <Color> element value.
DECLARE @XMLDoc xml;       
SET @XMLDoc = 
'<Root>
  <ProductDescription ProductID="1" ProductName="Road Bike">
    <Features>
      <Warranty>1 year parts and labor</Warranty>
      <Material>Aluminium</Material>
      <Color>Silver</Color>
      <BikeFrame>Strong long lasting</BikeFrame>
    </Features>
  </ProductDescription>
</Root>';
                      
SET @XMLDoc.modify('replace value of             
(/Root/ProductDescription/Features/Color/text())[1] with "Black"')   
          
SELECT @XMLDoc;

-- Listing 5-12. Updating ProductName attribute.
DECLARE @XMLDoc xml;       
SET @XMLDoc = 
'<Root>
  <ProductDescription ProductID="1" ProductName="Road Bike">
    <Features>
      <Warranty>1 year parts and labor</Warranty>
      <Material>Aluminium</Material>
      <Color>Silver</Color>
      <BikeFrame>Strong long lasting</BikeFrame>
    </Features>
  </ProductDescription>
</Root>';
                      
SET @XMLDoc.modify('replace value of             
	(/Root/ProductDescription/@ProductName)[1] with "Mountain Bike"');
SELECT @XMLDoc;

-- Listing 5-13. Deleting the ProductName attribute from an XML instance.
DECLARE @XMLDoc xml;       
SET @XMLDoc = 
'<Root>
  <ProductDescription ProductID="1" ProductName="Road Bike">
    <Features>
      <Warranty>1 year parts and labor</Warranty>
      <Material>Aluminium</Material>
      <Color>Silver</Color>
      <BikeFrame>Strong long lasting</BikeFrame>
    </Features>
  </ProductDescription>
</Root>';
                      
SET @XMLDoc.modify('delete /Root/ProductDescription/@ProductName')
          
SELECT @XMLDoc;

-- Listing 5-14. Deleting all attributes of the ProductDescription element.
DECLARE @XMLDoc xml;       
SET @XMLDoc = 
'<Root>
  <ProductDescription ProductID="1" ProductName="Road Bike">
    <Features>
      <Warranty>1 year parts and labor</Warranty>
      <Material>Aluminium</Material>
      <Color>Silver</Color>
      <BikeFrame>Strong long lasting</BikeFrame>
    </Features>
  </ProductDescription>
</Root>';
                      
SET @XMLDoc.modify('delete /Root/ProductDescription/@*')
          
SELECT @XMLDoc; 

-- Listing 5-15. Deleting the Color element from an XML instance. 
DECLARE @XMLDoc xml;       
SET @XMLDoc = 
'<Root>
  <ProductDescription ProductID="1" ProductName="Road Bike">
    <Features>
      <Warranty>1 year parts and labor</Warranty>
      <Material>Aluminium</Material>
      <Color>Silver</Color>
      <BikeFrame>Strong long lasting</BikeFrame>
    </Features>
  </ProductDescription>
</Root>';
                      
SET @XMLDoc.modify('delete /Root/ProductDescription/Features/Color')
          
SELECT @XMLDoc;

-- Listing 5-16. Deleting all child elements from the Features element.
DECLARE @XMLDoc xml;       
SET @XMLDoc = 
'<Root>
  <ProductDescription ProductID="1" ProductName="Road Bike">
    <Features>
      <Warranty>1 year parts and labor</Warranty>
      <Material>Aluminium</Material>
      <Color>Silver</Color>
      <BikeFrame>Strong long lasting</BikeFrame>
    </Features>
  </ProductDescription>
</Root>';
                      
SET @XMLDoc.modify('delete /Root/ProductDescription/Features/*')
          
SELECT @XMLDoc;
