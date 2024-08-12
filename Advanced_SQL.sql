--- Advanced SQL Analysis Project: Michael Romm

GO
USE AdventureWorks2019
GO

--- Q1: Write a SQL query that retrieves the ProductID, Name, Color, ListPrice, and Size of products that are not included in any sales orders:

SELECT 
	p.ProductID,
	p.Name,
	p.Color,
	p.ListPrice,
	p.Size
FROM Production.Product as p
WHERE p.ProductID NOT IN 
		(SELECT soh.ProductID
		 FROM Sales.SalesOrderDetail as soh 
		 JOIN Sales.SpecialOfferProduct as sof ON sof.ProductID=soh.ProductID 
		 JOIN Production.Product as pp ON pp.ProductID=sof.ProductID)
ORDER BY p.ProductID;

--- Q2: Construct a SQL query to fetch the CustomerID, Last Name, and First Name of customers who have not placed any sales orders:

SELECT 
	s.CustomerID,
	ISNULL(p.LastName,'Unknown') as LastName,
	ISNULL(p.FirstName,'Unknown') as FirstName
FROM Person.Person as p 
RIGHT JOIN Sales.Customer as s ON p.BusinessEntityID=s.CustomerID
WHERE s.CustomerID NOT IN 
		(SELECT ss.CustomerID
		FROM Sales.SalesOrderHeader as ss)
ORDER BY s.CustomerID;

--- Q3: Develop an SQL query to find the top 10 customers based on the count of their orders, along with their first and last names:

WITH CustomerTopOrder AS 
(
SELECT 
	top 10 count(s.SalesOrderID) as CountOfOrders,
	s.CustomerID,
	p.FirstName,
	p.LastName
FROM Sales.SalesOrderHeader as s 
JOIN Sales.Customer as c ON s.CustomerID=c.CustomerID
JOIN Person.Person as p ON c.PersonID=p.BusinessEntityID
GROUP BY s.CustomerID, p.FirstName, p.LastName
ORDER BY CountOfOrders DESC
)

SELECT CustomerID,FirstName,LastName,CountOfOrders
FROM CustomerTopOrder;

--- Q4: Create a SQL query to display the first name, last name, job title, hire date, and the count of employees sharing the same job title:

SELECT 
    p.FirstName, 
    p.LastName, 
    e.JobTitle, 
    e.HireDate,
    COUNT(*) OVER (PARTITION BY e.JobTitle) as CountOfTitle
FROM Person.Person as p 
JOIN HumanResources.Employee as e ON p.BusinessEntityID = e.BusinessEntityID;

--- Q5: Write an SQL query to retrieve the SalesOrderID, CustomerID, Last Name, First Name, OrderDate, and the date of the previous order for each customer:

WITH OrderDateRank AS 
(
SELECT 
	s.SalesOrderID,
	s.CustomerID, 
	p.LastName, 
	p.FirstName, 
	s.OrderDate,
	LAG(s.OrderDate) OVER (PARTITION BY s.CustomerID ORDER BY s.OrderDate) as PreviousOrder,
	RANK() OVER (PARTITION BY s.CustomerID ORDER BY s.OrderDate DESC) as RN
FROM sales.SalesOrderHeader as s 
JOIN sales.Customer as c ON s.CustomerID = c.CustomerID
JOIN Person.Person as p ON c.PersonID = p.BusinessEntityID
)

SELECT  
	SalesOrderID,
	CustomerID, 
	LastName, 
	FirstName, 
	OrderDate,
	PreviousOrder
FROM OrderDateRank
WHERE RN=1;

--- Q6: Formulate a SQL query to find the year, SalesOrderID, last name, first name, and total sales amount for the year with the highest total sales:

WITH OrderSumRN AS 
(
SELECT 
	YEAR(soh.OrderDate) as YY, 
	sod.SalesOrderID, 
	SUM(UnitPrice * (1 - UnitPriceDiscount) * OrderQty) as Total,
	ROW_NUMBER() OVER (PARTITION BY YEAR(soh.OrderDate) ORDER BY SUM(UnitPrice * (1 - UnitPriceDiscount) * OrderQty) DESC) as RN
FROM sales.SalesOrderDetail as sod 
JOIN Sales.SalesOrderHeader as soh ON sod.SalesOrderID = soh.SalesOrderID
GROUP BY sod.SalesOrderID, YEAR(soh.OrderDate)
)

SELECT 
    YY,
    soh.SalesOrderID,
	p.LastName,
	p.FirstName,
    Total
FROM OrderSumRN as osrn
JOIN Sales.SalesOrderHeader as soh ON osrn.SalesOrderID = soh.SalesOrderID
JOIN Sales.Customer as c ON soh.CustomerID = c.CustomerID
JOIN Person.Person as p ON c.PersonID = p.BusinessEntityID
WHERE RN = 1;

--- Q7: Create a SQL query to pivot the count of orders per month for each year from 2011 to 2014:

SELECT 
	Month,
	ISNULL([2011], 0) as [2011],
	ISNULL([2012], 0) as [2012],
	ISNULL([2013], 0) as [2013],
	ISNULL([2014], 0) as [2014]
FROM 
	(SELECT 
        MONTH(soh.OrderDate) as Month,
        YEAR(soh.OrderDate) as Year,
        COUNT(soh.SalesOrderID) as OrdersPerYear
     FROM Sales.SalesOrderHeader as soh
     GROUP BY YEAR(soh.OrderDate),MONTH(soh.OrderDate)) as OrderPerYearMonth
PIVOT (SUM(OrdersPerYear) FOR Year IN ([2011], [2012], [2013], [2014])) as pivottbl
ORDER BY Month;

--- Q8: Develop a SQL query to calculate the total and cumulative sum of sales prices per year and month, including a grand total:

WITH 
SumPerYearMonth AS 
(
 SELECT 
	YEAR(soh.OrderDate) as YY,
	MONTH(soh.OrderDate) as MM, 
	SUM(sod.UnitPrice - (sod.UnitPrice * sod.UnitPriceDiscount)) as SUM_price
 FROM Sales.SalesOrderHeader as soh JOIN Sales.SalesOrderDetail as sod ON soh.SalesOrderID = sod.SalesOrderID
 GROUP BY YEAR(soh.OrderDate), MONTH(soh.OrderDate)
),
SumCumRank AS 
(
 SELECT 
	*,
	SUM(SUM_price) OVER (PARTITION BY YY ORDER BY MM ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as CUM_SUM,
	ROW_NUMBER() OVER (PARTITION BY YY ORDER BY MM) as RN
 FROM SumPerYearMonth
),
final_tbl AS
(
 SELECT 
	YY,
	CAST(MM AS nvarchar) as MM,
	SUM_price,
	CUM_SUM,
	RN
 FROM SumCumRank
    UNION ALL
 SELECT 
	YEAR(soh.OrderDate),
	'grand_year_total',
	NULL,
	SUM(sod.UnitPrice - (sod.UnitPrice * sod.UnitPriceDiscount)),
	13 as RN
 FROM Sales.SalesOrderHeader as soh JOIN Sales.SalesOrderDetail as sod ON soh.SalesOrderID = sod.SalesOrderID
 GROUP BY YEAR(soh.OrderDate)
	UNION ALL
 SELECT 
	9999,
	'grand_all_total',
	NULL,
	SUM(sod.UnitPrice - (sod.UnitPrice * sod.UnitPriceDiscount)),
	14
 FROM Sales.SalesOrderHeader as soh JOIN Sales.SalesOrderDetail as sod ON soh.SalesOrderID=sod.SalesOrderID
)

SELECT 
	YY, 
	MM, 
	ROUND(SUM_price,2) as SUM_price,
	ROUND(CUM_SUM,2) as CUM_SUM
FROM final_tbl
ORDER BY YY, RN;

--- Q9: Construct an SQL query to retrieve the department name, employee ID, full name, hire date, seniority, previous employee name, previous employee hire date, and the difference in days between successive hires within the same department:

WITH EmpDateRow AS
(
SELECT 
	d.Name as DepartmentName,
	hre.BusinessEntityID as EmployeesID,
	CONCAT(pp.FirstName,' ',pp.LastName) as EmployeesFullName,
	hre.HireDate,
	DATEDIFF(month,hre.HireDate,GETDATE()) as Seniority,
	LAG(CONCAT(pp.FirstName,' ',pp.LastName)) OVER(PARTITION BY d.Name ORDER BY hre.HireDate ASC) as PreviusEmpName,
	LAG(hre.HireDate) OVER(PARTITION BY d.Name ORDER BY hre.HireDate ASC) as PreviusEmpDate,
	ROW_NUMBER() OVER(PARTITION BY d.Name ORDER BY hre.HireDate DESC) as row
FROM HumanResources.Employee as hre join Person.Person as pp on hre.BusinessEntityID=pp.BusinessEntityID
JOIN HumanResources.EmployeeDepartmentHistory as dh ON hre.BusinessEntityID=dh.BusinessEntityID
JOIN HumanResources.Department as d ON d.DepartmentID=dh.DepartmentID
)

SELECT 
	DepartmentName,
	EmployeesID,
	EmployeesFullName,
	HireDate,
	Seniority,
	PreviusEmpName,
	PreviusEmpDate,
	DATEDIFF(day,PreviusEmpDate,HireDate) AS DiffDays
FROM EmpDateRow
ORDER BY DepartmentName, row;

--- Q10: Write a SQL query to fetch the hire date, department ID, and a concatenated list of business entity IDs and full names for employees currently active in each department, grouped by hire date and department ID:

WITH emp1 AS
(
SELECT 
	hre.HireDate,
	dh.DepartmentID,
	hre.BusinessEntityID,
	CONCAT(pp.LastName,' ',pp.FirstName) as EmployeesFullName
FROM HumanResources.Employee as hre 
JOIN Person.Person as pp ON hre.BusinessEntityID = pp.BusinessEntityID
JOIN HumanResources.EmployeeDepartmentHistory as dh ON hre.BusinessEntityID = dh.BusinessEntityID
WHERE dh.EndDate IS NULL
)

SELECT 
    HireDate,
    DepartmentID,
    STRING_AGG(CONCAT(BusinessEntityID, ' - ', EmployeesFullName), ', ') as TeamEmploees
FROM emp1
GROUP BY HireDate, DepartmentID
ORDER BY HireDate DESC, DepartmentID DESC;
