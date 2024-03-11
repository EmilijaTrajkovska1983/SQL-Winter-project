CREATE DATABASE WinterProject

    USE WinterProject
    GO

-- Create the tables

CREATE TABLE dbo.SeniorityLevel
(
	Id INT IDENTITY(1,1) NOT NULL,
	[Name] NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_SeniorityLevel PRIMARY KEY CLUSTERED 
    (Id ASC)
)
GO


CREATE TABLE dbo.Location
(
	Id INT IDENTITY(1,1) NOT NULL,
	CountryName NVARCHAR(100) NULL,
	Continent NVARCHAR(100) NULL,
	Region NVARCHAR(100) NULL,
    CONSTRAINT PK_Location PRIMARY KEY CLUSTERED 
    (Id ASC)
)
GO


CREATE TABLE dbo.Department 
(
    Id INT IDENTITY(1,1) NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_Department PRIMARY KEY CLUSTERED
    (Id ASC)
)
GO


CREATE TABLE dbo.Employee
(
    ID INT IDENTITY(1,1) NOT NULL,
	FirstName NVARCHAR(100) NOT NULL,
	LastName NVARCHAR(100) NOT NULL,
	LocationId INT NOT NULL,
	SeniorityLevelId INT NOT NULL,
	DepartmentId INT NOT NULL,
    CONSTRAINT PK_Employee PRIMARY KEY CLUSTERED 
    (ID ASC)
)
GO


CREATE TABLE dbo.Salary
(
    Id BIGINT IDENTITY(1,1) NOT NULL,
    EmployeeId INT NOT NULL,
	[Month] SMALLINT NOT NULL,
	[Year] SMALLINT NOT NULL,
	GrossAmount DECIMAL(18,2) NOT NULL,
	NetAmount DECIMAL(18,2) NOT NULL,
	RegularWorkAmount DECIMAL(18,2) NOT NULL,
    BonusAmount DECIMAL(18,2) NOT NULL,
    OvertimeAmount DECIMAL(18,2) NOT NULL,
    VacationDays SMALLINT NOT NULL,
    SickLeaveDays SMALLINT NOT NULL,
    CONSTRAINT PK_Salary PRIMARY KEY CLUSTERED 
    (ID ASC)
)
GO


-- Add FOREIGN KEYS

ALTER TABLE dbo.Employee WITH CHECK
ADD CONSTRAINT FK_SeniorityLevel_Employee 
FOREIGN KEY (SeniorityLevelId)
REFERENCES dbo.SeniorityLevel(ID)

ALTER TABLE dbo.Employee WITH CHECK
ADD CONSTRAINT FK_Location_Employee 
FOREIGN KEY (LocationId)
REFERENCES dbo.Location(ID)

ALTER TABLE dbo.Employee WITH CHECK
ADD CONSTRAINT FK_Department_Employee 
FOREIGN KEY (DepartmentId)
REFERENCES dbo.Department(ID)

ALTER TABLE dbo.Salary WITH CHECK
ADD CONSTRAINT FK_Salary_Employee 
FOREIGN KEY (EmployeeId)
REFERENCES dbo.Employee(ID)


-- Insert SeniorityLevel
    -- Seniority levels should be inserted manually.

INSERT dbo.SeniorityLevel ([Name])
VALUES ('Junior'), 
    ('Intermediate'), 
    ('Senior'), 
    ('Lead'), 
    ('Project Manager'), 
    ('Division Manager'), 
    ('Office Manager'), 
    ('CEO'), 
    ('CTO'), 
    ('CIO')

SELECT * FROM SeniorityLevel


-- Insert Location
    -- List of locations should be imported from Application.Countries table in WideWorldImporters database.
    -- Table should contain 190 records after import.


SELECT * FROM WideWorldImporters.Application.Countries

INSERT INTO [Location] (CountryName, Continent, Region)
SELECT ac.CountryName, ac.Continent, ac.Region
FROM WideWorldImporters.Application.Countries as ac

SELECT * FROM [Location]


-- Insert Department
    -- Departments should be inserted manually.

INSERT dbo.Department ([Name])
VALUES ('Personal Banking & Operations'),
    ('Digital Banking Department'),
    ('Retail Banking & Marketing Department'),
    ('Wealth Management & Third Party Products'),
    ('International Banking Division & DFB'),
    ('Treasury'),
    ('Information Technology'),
    ('Corporate Communication'),
    ('Support Services & Branch Expansion'),
    ('Human Resourses')

SELECT * FROM Department


-- Insert Employee
    -- List of employees should be imported from Application.People table in WideWorldImporters database.
    -- Table should contain 1111 records after import.

SELECT * FROM Employee
SELECT * FROM WideWorldImporters.Application.People


INSERT INTO dbo.Employee (FirstName, LastName, LocationID, SeniorityLevelID, DepartmentID)
SELECT LEFT(FullName, CHARINDEX(' ', FullName) -1) AS FirstName,
    SUBSTRING(FullName, CHARINDEX(' ',FullName) +1, LEN(FullName)) AS LastName,
    NTILE(190) OVER (ORDER BY PersonID) as LocatonID,
    NTILE(10) OVER(ORDER BY PersonID ) AS SeniorityLevelID,
    NTILE(10) OVER (ORDER BY PersonID) as DepartmentID
FROM WideWorldImporters.Application.People 


-- Insert Salary

SELECT * FROM Salary

DECLARE @FromDate DATETIME, @ToDate DATETIME
SET @FromDate = '2001-01-01'
SET @ToDate = '2020-12-31'

SELECT TOP (DATEDIFF(MONTH, @FromDate, @ToDate)+1) 
    MONTH(DATEADD(MONTH, number, @FromDate)) as Month,
    YEAR(DATEADD(MONTH, number, @FromDate)) as Year
FROM [master].dbo.spt_values 
WHERE [type] = N'P' ORDER BY number


CREATE VIEW dbo.MonthYear as
SELECT TOP (DATEDIFF(MONTH, '2001-01-01', '2020-12-31')+1)
    MONTH(DATEADD(MONTH, number, '2001-01-01')) as Month,
    YEAR(DATEADD(MONTH, number,'2001-01-01')) as Year 
FROM [master].dbo.spt_values 
WHERE [type] = N'P' ORDER BY number


CREATE View dbo.Employees as
SELECT ID as EmployeeID 
FROM dbo.Employee


CREATE TABLE #GrossAmountTemp
(
    ID INT IDENTITY (1,1) NOT NULL,
    EmployeeID INT NOT NULL,
    Month SMALLINT NOT NULL,
    Year SMALLINT NOT NULL,
    GrossAmount INT NOT NULL
)

INSERT INTO #GrossAmountTemp
SELECT  e.EmployeeID,
        m.Month,
        m.Year,
        FLOOR(RAND(CHECKSUM(NEWID()))*(60000-30000+1)+30000) as GrossAmount
FROM dbo.MonthYear as m
CROSS JOIN dbo.Employees e
ORDER BY EmployeeID

SELECT * FROM #GrossAmountTemp

-- Net Amount (90% of the gross amount)

SELECT  EmployeeID, 
        Month,
        Year,
        GrossAmount,
        (GrossAmount * 0.9) as NetAmount
From #GrossAmountTemp

-- RegularWorkAmount (80% of the Nett Amount)

SELECT *, (GrossAmount * 0.9) * 0.8 as RegularWorkAmount
FROM #GrossAmountTemp

-- BonusAmount

SELECT *, ((GrossAmount * 0.9) - ((GrossAmount * 0.9) * 0.8)) as BonusAmount
FROM #GrossAmountTemp
WHERE Month %2!=0 

-- OvertimeAmount

SELECT *, ((GrossAmount * 0.9) - ((GrossAmount * 0.9) * 0.8)) as OvertimeAmount
FROM #GrossAmountTemp
WHERE Month %2=0 


CREATE TABLE #SalaryTemp
(
    EmployeeID INT NOT NULL,
    Month SMALLINT NOT NULL,
    Year SMALLINT NOT NULL,
    GrossAmount DECIMAL(18,2) NOT NULL,
    NetAmount DECIMAL(18,2) NOT NULL,  
    RegularWorkAmount DECIMAL(18,2) NOT NULL,
    BonusAmount DECIMAL(18,2) NOT NULL,
    OverTimeAmount DECIMAL(18,2) NOT NULL,
    VacationDays SMALLINT NULL,
    SickLeaveDays SMALLINT NULL,
)

INSERT INTO #SalaryTemp (EmployeeID, Month, Year, GrossAmount, NetAmount, RegularWorkAmount, BonusAmount, OverTimeAmount)
    SELECT  EmployeeID, 
            Month, 
            Year, 
            GrossAmount,
            (GrossAmount * 0.9) as NetAmount, 
            (GrossAmount * 0.9) * 0.8 as RegularWorkAmount,
            ISNULL(((SELECT ((GrossAmount * 0.9) - ((GrossAmount * 0.9) * 0.8))
            WHERE [Month] %2!=0)), 0) as BonusAmount,
            ISNULL(((SELECT ((GrossAmount * 0.9) - ((GrossAmount * 0.9) * 0.8))
            WHERE [Month] %2=0)),0) as OvertimeAmount
    FROM #GrossAmountTemp


SELECT * from #SalaryTemp
order by EmployeeID


INSERT INTO Salary (EmployeeID, Month, Year, GrossAmount, NetAmount, RegularWorkAmount, BonusAmount, OverTimeAmount, VacationDays, SickLeaveDays)
SELECT              EmployeeID, Month, Year, GrossAmount, NetAmount, RegularWorkAmount, BonusAmount, OverTimeAmount, 
                    ISNULL(NULL, 0) as VacationDays,   
                    ISNULL(NULL, 0) as SickLeaveDays
FROM #SalaryTemp

SELECT * FROM Salary
ORDER BY EmployeeId


---	All employees use 10 vacation days in July and 10 Vacation days in December

UPDATE Salary
SET VacationDays = '10' 
WHERE Month in (7,12)


-- Additionally random vacation days and sickLeaveDays should be generated with the following script:

UPDATE Salary SET vacationDays = vacationDays + (EmployeeId % 2)
WHERE (EmployeeId + MONTH + year)%5 = 1
GO

UPDATE Salary SET SickLeaveDays = EmployeeId%8, vacationDays = vacationDays + (EmployeeId % 3)
WHERE (employeeId + MONTH + year)%5 = 2
GO

------------------------------------------------------------------------------------------------------

SELECT * FROM Salary
ORDER BY EmployeeId

-- If everything is done as expected the following query should return 0 rows:

SELECT * FROM Salary
WHERE NetAmount <> (regularWorkAmount + BonusAmount + OverTimeAmount)




