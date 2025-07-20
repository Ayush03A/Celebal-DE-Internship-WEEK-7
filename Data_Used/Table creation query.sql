CREATE TABLE [dbo].[CUST_MSTR] (
    CustomerID INT NOT NULL,
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    Email NVARCHAR(100),
    [Date] DATE,             -- For the date from filename, format: 2019-11-12
    CONSTRAINT PK_CUST_MSTR PRIMARY KEY (CustomerID, [Date])
);

CREATE TABLE [dbo].[master_child] (
    MasterID INT NOT NULL,
    ChildID INT NOT NULL,
    ChildName NVARCHAR(100),
    [Date] DATE,             -- For the date from filename, format: 2019-11-12
    DateKey INT,             -- For the date key from filename, format: 20191112
    CONSTRAINT PK_master_child PRIMARY KEY (MasterID, ChildID, [Date])
);

CREATE TABLE [dbo].[H_ECOM_Orders] (
    OrderID INT NOT NULL,
    CustomerID INT,
    OrderValue DECIMAL(18,2),
    OrderDate DATE,
    CONSTRAINT PK_H_ECOM_Orders PRIMARY KEY (OrderID)
);
