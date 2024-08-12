-- Sales SQL Database Setup Project: Michael Romm

GO
	USE MASTER
GO
	CREATE DATABASE Sales
GO
	USE Sales
GO 
CREATE TABLE SalesTerritory	
	(
	TerritoryID int IDENTITY(1,1) NOT NULL,
	[Name] nvarchar(50) NOT NULL, 
	CountryRegionCode nvarchar(3) NOT NULL,
	[Group] nvarchar(50) NOT NULL,
	SalesYTD money NOT NULL DEFAULT(0),
	SalesLastYear money NOT NULL DEFAULT(0),
	CostYTD money NOT NULL DEFAULT(0),
	CostLastYear money NOT NULL DEFAULT(0),
	rowguid uniqueidentifier NOT NULL DEFAULT NEWID() ROWGUIDCOL,
	ModifiedDate DATETIME NOT NULL DEFAULT(getdate()),
		CONSTRAINT PK_SalesTerritory PRIMARY KEY (TerritoryID),
		CONSTRAINT IX_SalesTerritory_rowguid UNIQUE NONCLUSTERED (rowguid),
		CONSTRAINT CK_CostLastYear_NonNegative CHECK ([CostLastYear]>=0),
		CONSTRAINT CK_SalesTerritory_CostYTD CHECK ([CostYTD]>=0),
		CONSTRAINT CK_SalesTerritory_SalesLastYear CHECK ([SalesLastYear]>=0),
		CONSTRAINT CK_SalesTerritory_SalesYTD CHECK ([SalesYTD]>=0)
	);
GO 
CREATE TABLE CreditCard 
	(
	CreditCardID int NOT NULL,
	CardType nvarchar(50) NOT NULL,
	CardNumber nvarchar(25) NOT NULL ,
	ExpMonth tinyint NOT NULL,
	ExpYear smallint NOT NULL,
	ModifiedDate datetime NOT NULL,
		CONSTRAINT PK_CreditCard PRIMARY KEY (CreditCardID)
	);
GO
CREATE TABLE Address 
	(
	AddressID int NOT NULL,
	AddressLine1 nvarchar(60) NOT NULL,
	AddressLine2 nvarchar(60),
	City nvarchar(30) NOT NULL,
	StateProvinceID int NOT NULL,
	PostalCode nvarchar(15) NOT NULL,
	SpatialLocation geography,
	rowguid uniqueidentifier NOT NULL,
	ModifiedDate datetime NOT NULL,
		CONSTRAINT PK_Address PRIMARY KEY (AddressID)
	);
GO
CREATE TABLE ShipMethod 
	(
	ShipMethodID int NOT NULL,
	Name nvarchar(50) NOT NULL,
	ShipBase money NOT NULL,
	ShipRate money NOT NULL,
	rowguid uniqueidentifier NOT NULL,
	ModifiedDate datetime NOT NULL,
		CONSTRAINT PK_ShipMethod PRIMARY KEY (ShipMethodID)
	);
GO
CREATE TABLE CurrencyRate 
	(
	CurrencyRateID int NOT NULL,
	CurrencyRateDate datetime NOT NULL,
	FromCurrencyCode nchar(3) NOT NULL,
	ToCurrencyCode nchar(3) NOT NULL,
	AveregeRate money NOT NULL,
	EndOfDatRate money NOT NULL,
	ModifiedDate datetime NOT NULL,
		CONSTRAINT PK_CurrencyRate PRIMARY KEY (CurrencyRateID)
	);
GO
CREATE TABLE SpecialOfferProduct 
	(
	SpecialOfferID int NOT NULL,
	ProductID int NOT NULL,
	rowguid uniqueidentifier NOT NULL,
	ModifiedDate datetime NOT NULL,
		CONSTRAINT PK_SpecialOfferProduct PRIMARY KEY (SpecialOfferID,ProductID)
	);
GO
CREATE TABLE Customer 
	(
	CustomerID int NOT NULL,
	PersonID int,
	StoreID int,
	TerritoryID int,
	AccountNumber nvarchar(15) NOT NULL,
	rowguid uniqueidentifier NOT NULL,
	ModifiedDate datetime NOT NULL,
		CONSTRAINT PK_Customer PRIMARY KEY (CustomerID),
		CONSTRAINT FK_Customer FOREIGN KEY (TerritoryID) REFERENCES SalesTerritory(TerritoryID)
	);
GO 
CREATE TABLE SalesPerson 
	(
	BusinessEntityID int NOT NULL,
	TerritoryID int,
	SalesQuota money ,
	Bonus money NOT NULL,
	ComissionPct smallmoney NOT NULL,
	SalesYTD money NOT NULL,
	SalesLastYear money NOT NULL,
	rowguid uniqueidentifier NOT NULL,
	ModifiedDate datetime NOT NULL,
		CONSTRAINT PK_SalesPerson PRIMARY KEY (BusinessEntityID),
		CONSTRAINT FK_SalesPerson FOREIGN KEY (TerritoryID) REFERENCES SalesTerritory(TerritoryID)
	);
GO 
CREATE TABLE SalesOrderHeader 
	(
	SalesOrderId int NOT NULL,
	RevisioNumber tinyint NOT NULL,
	OrderDate datetime NOT NULL,
	DueDate datetime NOT NULL,
	ShipDate datetime,
	[Status] tinyint NOT NULL,
	OnlineOrderFlag bit NOT NULL,
	SalesOrderNumber nvarchar(50) NOT NULL,
	PurchaseOrderNumber	nvarchar(50),
	AccountNumber nvarchar(30),
	CustomerID int NOT NULL,
	SalesPersonID int,
	TerritoryID	int,
	BillToAddressID	int NOT NULL,
	ShipToAddressID	int NOT NULL,
	ShipMethodID int NOT NULL,
	CreditCardID int,
	CreditCardApprovalCode varchar(15),
	CurrencyRateID int,
	SubTotal money NOT NULL,
	TaxAmt money NOT NULL,
	Freight	money NOT NULL,
	TotalDue money NOT NULL, 
	Comment nvarchar(256),
	rowguid uniqueidentifier NOT NULL,
	ModifiedDate datetime NOT NULL,
		CONSTRAINT PK_SalesOrderHeader PRIMARY KEY (SalesOrderId),
		CONSTRAINT FK_SalesOrderHeader_Customer FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),
		CONSTRAINT FK_FK_SalesOrderHeader_SalesTerritory FOREIGN KEY (TerritoryID) REFERENCES SalesTerritory(TerritoryID),
		CONSTRAINT FK_FK_SalesOrderHeader_ShipMethod FOREIGN KEY (ShipMethodID) REFERENCES ShipMethod(ShipMethodID),
		CONSTRAINT FK_SalesOrderHeader_SalesPerson FOREIGN KEY (SalesPersonID) REFERENCES SalesPerson(BusinessEntityID),
		CONSTRAINT FK_SalesOrderHeader_Address_BillToAddressID FOREIGN KEY (BillToAddressID) REFERENCES Address(AddressID),
		CONSTRAINT FK_SalesOrderHeader_ShipToAddressID FOREIGN KEY (ShipToAddressID) REFERENCES Address(AddressID),
		CONSTRAINT FK_SalesOrderHeader_CreditCard FOREIGN KEY (CreditCardID) REFERENCES CreditCard(CreditCardID),
		CONSTRAINT FK_SalesOrderHeader_CurrencyRate FOREIGN KEY (CurrencyRateID) REFERENCES CurrencyRate(CurrencyRateID)
	);
GO
CREATE TABLE SalesOrderDetail 
	(
	SalesOrderId int NOT NULL,
	SaleOrderDetailID int NOT NULL,
	CarrierTrackingNumber nvarchar(25),
	OrderQty smallint NOT NULL,
	ProductID int NOT NULL,
	SpecialOfferID int NOT NULL,
	UnitPrice money NOT NULL,
	UnitPriceDiscount money NOT NULL,
	LineTotal numeric NOT NULL,
	rowguid uniqueidentifier NOT NULL,
	ModifiedDate datetime NOT NULL,
		CONSTRAINT PK_SalesOrderDetail PRIMARY KEY (SalesOrderId,SaleOrderDetailID),
		CONSTRAINT FK_SalesPerson_SpecialOfferProduct FOREIGN KEY (SpecialOfferID,ProductID) REFERENCES SpecialOfferProduct(SpecialOfferID,ProductID),
		CONSTRAINT FK_SalesPerson_SalesOrderHeader FOREIGN KEY (SalesOrderId) REFERENCES SalesOrderHeader(SalesOrderId)
	);
GO
INSERT INTO SalesTerritory ([Name],CountryRegionCode,[Group],SalesYTD,SalesLastYear,ModifiedDate)
VALUES 
	('Northwest','US','North America',7887186.7882,3298694.4938,'2008-04-30 00:00:00.000'),
	('Northeast','US','North America',2402176.8476,3607148.9371,'2008-04-30 00:00:00.000'),
	('Central','US','North America',3072175.118,3205014.0767,'2008-04-30 00:00:00.000'),
	('Southwest','US','North America',10510853.8739,5366575.7098,'2008-04-30 00:00:00.000'),
	('Southeast','US','North America',2538667.2515,3925071.4318,'2008-04-30 00:00:00.000'),
	('Canada','CA','North America',6771829.1376,5693988.86,'2008-04-30 00:00:00.000'),
	('France','FR','Europe',4772398.3078,2396539.7601,'2008-04-30 00:00:00.000'),
	('Germany','DE','Europe',3805202.3478,1307949.7917,'2008-04-30 00:00:00.000'),
	('Australia','AU','Pacific',5977814.9154,2278548.9776,'2008-04-30 00:00:00.000'),
	('United Kingdom','GB','Europe',5012905.3656,1635823.3967,'2008-04-30 00:00:00.000');
GO
INSERT INTO SalesPerson
SELECT * FROM AdventureWorks2017.Sales.SalesPerson;
GO
INSERT INTO ShipMethod
VALUES 
	(1,'XRQ - TRUCK GROUND',3.95,0.99,'6BE756D9-D7BE-4463-8F2C-AE60C710D606','2008-04-30 00:00:00.000'),
	(2,'ZY - EXPRESS',9.95,1.99,'3455079B-F773-4DC6-8F1E-2A58649C4AB8','2008-04-30 00:00:00.000'),
	(3,'OVERSEAS - DELUXE',29.95,2.99,'22F4E461-28CF-4ACE-A980-F686CF112EC8','2008-04-30 00:00:00.000'),
	(4,'OVERNIGHT J-FAST',21.95,1.29,'107E8356-E7A8-463D-B60C-079FFF467F3F','2008-04-30 00:00:00.000'),
	(5,'CARGO TRANSPORT 5',8.99,1.49,'B166019A-B134-4E76-B957-2B0490C610ED','2008-04-30 00:00:00.000');
GO
INSERT INTO CreditCard
SELECT * FROM AdventureWorks2017.Sales.CreditCard;
GO
INSERT INTO SpecialOfferProduct
SELECT * FROM AdventureWorks2017.Sales.SpecialOfferProduct;
GO
INSERT INTO Address
SELECT * FROM AdventureWorks2017.Person.Address;
GO
INSERT INTO Customer 
SELECT * FROM AdventureWorks2017.Sales.Customer;
GO
INSERT INTO CurrencyRate
SELECT * FROM AdventureWorks2017.Sales.CurrencyRate;
GO
INSERT INTO SalesOrderHeader
SELECT * FROM AdventureWorks2017.Sales.SalesOrderHeader;
GO
INSERT INTO SalesOrderDetail
SELECT * FROM AdventureWorks2017.Sales.SalesOrderDetail;
