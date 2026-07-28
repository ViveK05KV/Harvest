/* =====================================================================
   Fruit Wholesale Management System
   01_CreateDatabase_Tables.sql
   Creates the database and all core tables, primary keys, foreign keys
   and default constraints.
   ===================================================================== */

IF DB_ID('FruitWholesaleDB') IS NULL
BEGIN
    CREATE DATABASE FruitWholesaleDB;
END
GO

USE FruitWholesaleDB;
GO

/* =====================================================================
   Drop all tables up front, in dependency-safe (child-before-parent)
   order, so this script can be re-run at any time. Each CREATE TABLE
   section below still guards with IF OBJECT_ID(...) IS NULL for safety,
   but relies on this block for the correct drop order.
   ===================================================================== */
IF OBJECT_ID('dbo.CashLedger', 'U') IS NOT NULL DROP TABLE dbo.CashLedger;
IF OBJECT_ID('dbo.SupplierLedger', 'U') IS NOT NULL DROP TABLE dbo.SupplierLedger;
IF OBJECT_ID('dbo.ShopLedger', 'U') IS NOT NULL DROP TABLE dbo.ShopLedger;
IF OBJECT_ID('dbo.StockLedger', 'U') IS NOT NULL DROP TABLE dbo.StockLedger;
IF OBJECT_ID('dbo.FruitCostBasis', 'U') IS NOT NULL DROP TABLE dbo.FruitCostBasis;
IF OBJECT_ID('dbo.EmployeeWorkLog', 'U') IS NOT NULL DROP TABLE dbo.EmployeeWorkLog;
IF OBJECT_ID('dbo.EmployeeSupplyDay', 'U') IS NOT NULL DROP TABLE dbo.EmployeeSupplyDay;
IF OBJECT_ID('dbo.DailyExpense', 'U') IS NOT NULL DROP TABLE dbo.DailyExpense;
IF OBJECT_ID('dbo.SupplierPayments', 'U') IS NOT NULL DROP TABLE dbo.SupplierPayments;
IF OBJECT_ID('dbo.PurchaseItems', 'U') IS NOT NULL DROP TABLE dbo.PurchaseItems;
IF OBJECT_ID('dbo.Purchase', 'U') IS NOT NULL DROP TABLE dbo.Purchase;
IF OBJECT_ID('dbo.Collections', 'U') IS NOT NULL DROP TABLE dbo.Collections;
IF OBJECT_ID('dbo.SupplyItems', 'U') IS NOT NULL DROP TABLE dbo.SupplyItems;
IF OBJECT_ID('dbo.Supply', 'U') IS NOT NULL DROP TABLE dbo.Supply;
IF OBJECT_ID('dbo.ExpenseCategory', 'U') IS NOT NULL DROP TABLE dbo.ExpenseCategory;
IF OBJECT_ID('dbo.EmployeeMaster', 'U') IS NOT NULL DROP TABLE dbo.EmployeeMaster;
IF OBJECT_ID('dbo.SupplierMaster', 'U') IS NOT NULL DROP TABLE dbo.SupplierMaster;
IF OBJECT_ID('dbo.ShopMaster', 'U') IS NOT NULL DROP TABLE dbo.ShopMaster;
IF OBJECT_ID('dbo.RouteMaster', 'U') IS NOT NULL DROP TABLE dbo.RouteMaster;
IF OBJECT_ID('dbo.FruitMaster', 'U') IS NOT NULL DROP TABLE dbo.FruitMaster;
IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL DROP TABLE dbo.Users;
IF OBJECT_ID('dbo.CompanySettings', 'U') IS NOT NULL DROP TABLE dbo.CompanySettings;
GO

/* =====================================================================
   CompanySettings
   ===================================================================== */
IF OBJECT_ID('dbo.CompanySettings', 'U') IS NOT NULL DROP TABLE dbo.CompanySettings;
GO
CREATE TABLE dbo.CompanySettings
(
    CompanyID           INT IDENTITY(1,1)   NOT NULL,
    CompanyName         NVARCHAR(200)       NOT NULL,
    OwnerName           NVARCHAR(150)       NULL,
    Address              NVARCHAR(500)       NULL,
    Phone               NVARCHAR(20)        NULL,
    GSTNo               NVARCHAR(50)        NULL,
    LogoUrl             NVARCHAR(MAX)       NULL,
    OpeningCashBalance  DECIMAL(18,2)       NOT NULL CONSTRAINT DF_CompanySettings_OpeningCashBalance DEFAULT (0),
    CreatedAt           DATETIME2           NOT NULL CONSTRAINT DF_CompanySettings_CreatedAt DEFAULT (SYSUTCDATETIME()),
    UpdatedAt           DATETIME2           NULL,
    CONSTRAINT PK_CompanySettings PRIMARY KEY CLUSTERED (CompanyID)
);
GO

/* =====================================================================
   Users
   ===================================================================== */
IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL DROP TABLE dbo.Users;
GO
CREATE TABLE dbo.Users
(
    UserID          INT IDENTITY(1,1)  NOT NULL,
    FullName        NVARCHAR(150)      NOT NULL,
    Username        NVARCHAR(100)      NOT NULL,
    PasswordHash    NVARCHAR(300)      NOT NULL,
    Role            NVARCHAR(50)       NOT NULL, -- Admin, Manager, Accountant, Staff
    IsActive        BIT                NOT NULL CONSTRAINT DF_Users_IsActive DEFAULT (1),
    CreatedAt       DATETIME2          NOT NULL CONSTRAINT DF_Users_CreatedAt DEFAULT (SYSUTCDATETIME()),
    UpdatedAt       DATETIME2          NULL,
    CONSTRAINT PK_Users PRIMARY KEY CLUSTERED (UserID),
    CONSTRAINT UQ_Users_Username UNIQUE (Username)
);
GO

/* =====================================================================
   FruitMaster
   ===================================================================== */
IF OBJECT_ID('dbo.FruitMaster', 'U') IS NOT NULL DROP TABLE dbo.FruitMaster;
GO
CREATE TABLE dbo.FruitMaster
(
    FruitID     INT IDENTITY(1,1)  NOT NULL,
    FruitName   NVARCHAR(150)      NOT NULL,
    Unit        NVARCHAR(20)       NOT NULL, -- Kg, Box, Dozen, Piece
    IsActive    BIT                NOT NULL CONSTRAINT DF_FruitMaster_IsActive DEFAULT (1),
    CreatedAt   DATETIME2          NOT NULL CONSTRAINT DF_FruitMaster_CreatedAt DEFAULT (SYSUTCDATETIME()),
    UpdatedAt   DATETIME2          NULL,
    CONSTRAINT PK_FruitMaster PRIMARY KEY CLUSTERED (FruitID),
    CONSTRAINT UQ_FruitMaster_FruitName UNIQUE (FruitName)
);
GO

/* =====================================================================
   FruitCostBasis (weighted-average cost tracking for profit calculation
   — see database/08_AddProfitTracking.sql for the full design rationale)
   ===================================================================== */
IF OBJECT_ID('dbo.FruitCostBasis', 'U') IS NOT NULL DROP TABLE dbo.FruitCostBasis;
GO
CREATE TABLE dbo.FruitCostBasis
(
    FruitID          INT            NOT NULL,
    QuantityOnHand   DECIMAL(18,3)  NOT NULL CONSTRAINT DF_FruitCostBasis_QuantityOnHand DEFAULT (0),
    AverageCost      DECIMAL(18,4)  NOT NULL CONSTRAINT DF_FruitCostBasis_AverageCost DEFAULT (0),
    UpdatedAt        DATETIME2      NOT NULL CONSTRAINT DF_FruitCostBasis_UpdatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_FruitCostBasis PRIMARY KEY CLUSTERED (FruitID),
    CONSTRAINT FK_FruitCostBasis_FruitMaster FOREIGN KEY (FruitID) REFERENCES dbo.FruitMaster(FruitID)
);
GO

/* =====================================================================
   RouteMaster (a supply route groups a set of shops that share a
   delivery run — a wholesaler may run more than one route)
   ===================================================================== */
IF OBJECT_ID('dbo.RouteMaster', 'U') IS NOT NULL DROP TABLE dbo.RouteMaster;
GO
CREATE TABLE dbo.RouteMaster
(
    RouteID     INT IDENTITY(1,1)  NOT NULL,
    RouteName   NVARCHAR(150)      NOT NULL,
    Description NVARCHAR(500)      NULL,
    IsActive    BIT                NOT NULL CONSTRAINT DF_RouteMaster_IsActive DEFAULT (1),
    CreatedAt   DATETIME2          NOT NULL CONSTRAINT DF_RouteMaster_CreatedAt DEFAULT (SYSUTCDATETIME()),
    UpdatedAt   DATETIME2          NULL,
    CONSTRAINT PK_RouteMaster PRIMARY KEY CLUSTERED (RouteID),
    CONSTRAINT UQ_RouteMaster_RouteName UNIQUE (RouteName)
);
GO

/* =====================================================================
   ShopMaster (Customers)
   ===================================================================== */
IF OBJECT_ID('dbo.ShopMaster', 'U') IS NOT NULL DROP TABLE dbo.ShopMaster;
GO
CREATE TABLE dbo.ShopMaster
(
    ShopID          INT IDENTITY(1,1)  NOT NULL,
    ShopName        NVARCHAR(200)      NOT NULL,
    OwnerName       NVARCHAR(150)      NULL,
    Phone           NVARCHAR(20)       NULL,
    Address         NVARCHAR(500)      NULL,
    OpeningBalance  DECIMAL(18,2)      NOT NULL CONSTRAINT DF_ShopMaster_OpeningBalance DEFAULT (0),
    CreditLimit     DECIMAL(18,2)      NOT NULL CONSTRAINT DF_ShopMaster_CreditLimit DEFAULT (0),
    RouteID         INT                NULL,
    IsActive        BIT                NOT NULL CONSTRAINT DF_ShopMaster_IsActive DEFAULT (1),
    CreatedAt       DATETIME2          NOT NULL CONSTRAINT DF_ShopMaster_CreatedAt DEFAULT (SYSUTCDATETIME()),
    UpdatedAt       DATETIME2          NULL,
    CONSTRAINT PK_ShopMaster PRIMARY KEY CLUSTERED (ShopID),
    CONSTRAINT FK_ShopMaster_RouteMaster FOREIGN KEY (RouteID) REFERENCES dbo.RouteMaster(RouteID)
);
GO

/* =====================================================================
   SupplierMaster
   ===================================================================== */
IF OBJECT_ID('dbo.SupplierMaster', 'U') IS NOT NULL DROP TABLE dbo.SupplierMaster;
GO
CREATE TABLE dbo.SupplierMaster
(
    SupplierID      INT IDENTITY(1,1)  NOT NULL,
    SupplierName    NVARCHAR(200)      NOT NULL,
    Phone           NVARCHAR(20)       NULL,
    Address         NVARCHAR(500)      NULL,
    OpeningBalance  DECIMAL(18,2)      NOT NULL CONSTRAINT DF_SupplierMaster_OpeningBalance DEFAULT (0),
    IsActive        BIT                NOT NULL CONSTRAINT DF_SupplierMaster_IsActive DEFAULT (1),
    CreatedAt       DATETIME2          NOT NULL CONSTRAINT DF_SupplierMaster_CreatedAt DEFAULT (SYSUTCDATETIME()),
    UpdatedAt       DATETIME2          NULL,
    CONSTRAINT PK_SupplierMaster PRIMARY KEY CLUSTERED (SupplierID)
);
GO

/* =====================================================================
   EmployeeMaster
   A plain staff directory — employees have no fixed route or fixed
   working days. Which route (if any) and what job they did on a given
   day, and what they were paid for it, is recorded per entry in
   EmployeeWorkLog below.
   ===================================================================== */
IF OBJECT_ID('dbo.EmployeeMaster', 'U') IS NOT NULL DROP TABLE dbo.EmployeeMaster;
GO
CREATE TABLE dbo.EmployeeMaster
(
    EmployeeID  INT IDENTITY(1,1)  NOT NULL,
    FullName    NVARCHAR(150)      NOT NULL,
    Phone       NVARCHAR(20)       NULL,
    Address     NVARCHAR(500)      NULL,
    IsActive    BIT                NOT NULL CONSTRAINT DF_EmployeeMaster_IsActive DEFAULT (1),
    CreatedAt   DATETIME2          NOT NULL CONSTRAINT DF_EmployeeMaster_CreatedAt DEFAULT (SYSUTCDATETIME()),
    UpdatedAt   DATETIME2          NULL,
    CONSTRAINT PK_EmployeeMaster PRIMARY KEY CLUSTERED (EmployeeID)
);
GO

/* =====================================================================
   Supply (header) + SupplyItems
   ===================================================================== */
IF OBJECT_ID('dbo.SupplyItems', 'U') IS NOT NULL DROP TABLE dbo.SupplyItems;
IF OBJECT_ID('dbo.Supply', 'U') IS NOT NULL DROP TABLE dbo.Supply;
GO
CREATE TABLE dbo.Supply
(
    SupplyID     INT IDENTITY(1,1)  NOT NULL,
    SupplyDate   DATE               NOT NULL,
    ShopID       INT                NOT NULL,
    InvoiceNo    NVARCHAR(50)       NOT NULL,
    Remarks      NVARCHAR(500)      NULL,
    TotalAmount  DECIMAL(18,2)      NOT NULL CONSTRAINT DF_Supply_TotalAmount DEFAULT (0),
    CreatedBy    INT                NULL,
    CreatedAt    DATETIME2          NOT NULL CONSTRAINT DF_Supply_CreatedAt DEFAULT (SYSUTCDATETIME()),
    UpdatedAt    DATETIME2          NULL,
    CONSTRAINT PK_Supply PRIMARY KEY CLUSTERED (SupplyID),
    CONSTRAINT UQ_Supply_InvoiceNo UNIQUE (InvoiceNo),
    CONSTRAINT FK_Supply_ShopMaster FOREIGN KEY (ShopID) REFERENCES dbo.ShopMaster(ShopID),
    CONSTRAINT FK_Supply_Users FOREIGN KEY (CreatedBy) REFERENCES dbo.Users(UserID)
);
GO
CREATE TABLE dbo.SupplyItems
(
    SupplyItemID  INT IDENTITY(1,1)  NOT NULL,
    SupplyID      INT                NOT NULL,
    FruitID       INT                NOT NULL,
    Quantity      DECIMAL(18,3)      NOT NULL,
    UnitPrice     DECIMAL(18,2)      NOT NULL,
    TotalAmount   DECIMAL(18,2)      NOT NULL,
    CostBasis     DECIMAL(18,4)      NOT NULL CONSTRAINT DF_SupplyItems_CostBasis DEFAULT (0), -- weighted-avg fruit cost at time of sale; see 08_AddProfitTracking.sql
    CONSTRAINT PK_SupplyItems PRIMARY KEY CLUSTERED (SupplyItemID),
    CONSTRAINT FK_SupplyItems_Supply FOREIGN KEY (SupplyID) REFERENCES dbo.Supply(SupplyID) ON DELETE CASCADE,
    CONSTRAINT FK_SupplyItems_FruitMaster FOREIGN KEY (FruitID) REFERENCES dbo.FruitMaster(FruitID)
);
GO

/* =====================================================================
   Collections
   ===================================================================== */
IF OBJECT_ID('dbo.Collections', 'U') IS NOT NULL DROP TABLE dbo.Collections;
GO
CREATE TABLE dbo.Collections
(
    CollectionID     INT IDENTITY(1,1)  NOT NULL,
    CollectionDate   DATE               NOT NULL,
    ShopID           INT                NOT NULL,
    AmountReceived   DECIMAL(18,2)      NOT NULL,
    DiscountAmount   DECIMAL(18,2)      NOT NULL CONSTRAINT DF_Collections_DiscountAmount DEFAULT (0),
    PaymentMode      NVARCHAR(30)       NOT NULL, -- Cash, Bank, UPI, Cheque
    ReferenceNumber  NVARCHAR(100)      NULL,
    Remarks          NVARCHAR(500)      NULL,
    CreatedBy        INT                NULL,
    CreatedAt        DATETIME2          NOT NULL CONSTRAINT DF_Collections_CreatedAt DEFAULT (SYSUTCDATETIME()),
    UpdatedAt        DATETIME2          NULL,
    CONSTRAINT PK_Collections PRIMARY KEY CLUSTERED (CollectionID),
    CONSTRAINT FK_Collections_ShopMaster FOREIGN KEY (ShopID) REFERENCES dbo.ShopMaster(ShopID),
    CONSTRAINT FK_Collections_Users FOREIGN KEY (CreatedBy) REFERENCES dbo.Users(UserID)
);
GO

/* =====================================================================
   Purchase (header) + PurchaseItems
   ===================================================================== */
IF OBJECT_ID('dbo.PurchaseItems', 'U') IS NOT NULL DROP TABLE dbo.PurchaseItems;
IF OBJECT_ID('dbo.Purchase', 'U') IS NOT NULL DROP TABLE dbo.Purchase;
GO
CREATE TABLE dbo.Purchase
(
    PurchaseID   INT IDENTITY(1,1)  NOT NULL,
    PurchaseDate DATE               NOT NULL,
    SupplierID   INT                NOT NULL,
    InvoiceNo    NVARCHAR(50)       NOT NULL,
    Remarks      NVARCHAR(500)      NULL,
    TotalAmount  DECIMAL(18,2)      NOT NULL CONSTRAINT DF_Purchase_TotalAmount DEFAULT (0),
    CreatedBy    INT                NULL,
    CreatedAt    DATETIME2          NOT NULL CONSTRAINT DF_Purchase_CreatedAt DEFAULT (SYSUTCDATETIME()),
    UpdatedAt    DATETIME2          NULL,
    CONSTRAINT PK_Purchase PRIMARY KEY CLUSTERED (PurchaseID),
    CONSTRAINT UQ_Purchase_InvoiceNo UNIQUE (InvoiceNo),
    CONSTRAINT FK_Purchase_SupplierMaster FOREIGN KEY (SupplierID) REFERENCES dbo.SupplierMaster(SupplierID),
    CONSTRAINT FK_Purchase_Users FOREIGN KEY (CreatedBy) REFERENCES dbo.Users(UserID)
);
GO
CREATE TABLE dbo.PurchaseItems
(
    PurchaseItemID  INT IDENTITY(1,1)  NOT NULL,
    PurchaseID      INT                NOT NULL,
    FruitID         INT                NOT NULL,
    Quantity        DECIMAL(18,3)      NOT NULL,
    PurchasePrice   DECIMAL(18,2)      NOT NULL,
    TotalAmount     DECIMAL(18,2)      NOT NULL,
    CONSTRAINT PK_PurchaseItems PRIMARY KEY CLUSTERED (PurchaseItemID),
    CONSTRAINT FK_PurchaseItems_Purchase FOREIGN KEY (PurchaseID) REFERENCES dbo.Purchase(PurchaseID) ON DELETE CASCADE,
    CONSTRAINT FK_PurchaseItems_FruitMaster FOREIGN KEY (FruitID) REFERENCES dbo.FruitMaster(FruitID)
);
GO

/* =====================================================================
   SupplierPayments
   ===================================================================== */
IF OBJECT_ID('dbo.SupplierPayments', 'U') IS NOT NULL DROP TABLE dbo.SupplierPayments;
GO
CREATE TABLE dbo.SupplierPayments
(
    SupplierPaymentID  INT IDENTITY(1,1)  NOT NULL,
    PaymentDate         DATE               NOT NULL,
    SupplierID           INT                NOT NULL,
    AmountPaid           DECIMAL(18,2)      NOT NULL,
    DiscountAmount        DECIMAL(18,2)      NOT NULL CONSTRAINT DF_SupplierPayments_DiscountAmount DEFAULT (0),
    PaymentMode          NVARCHAR(30)       NOT NULL,
    ReferenceNumber      NVARCHAR(100)      NULL,
    Remarks               NVARCHAR(500)      NULL,
    CreatedBy             INT                NULL,
    CreatedAt             DATETIME2          NOT NULL CONSTRAINT DF_SupplierPayments_CreatedAt DEFAULT (SYSUTCDATETIME()),
    UpdatedAt             DATETIME2          NULL,
    CONSTRAINT PK_SupplierPayments PRIMARY KEY CLUSTERED (SupplierPaymentID),
    CONSTRAINT FK_SupplierPayments_SupplierMaster FOREIGN KEY (SupplierID) REFERENCES dbo.SupplierMaster(SupplierID),
    CONSTRAINT FK_SupplierPayments_Users FOREIGN KEY (CreatedBy) REFERENCES dbo.Users(UserID)
);
GO

/* =====================================================================
   ExpenseCategory
   ===================================================================== */
IF OBJECT_ID('dbo.ExpenseCategory', 'U') IS NOT NULL DROP TABLE dbo.ExpenseCategory;
GO
CREATE TABLE dbo.ExpenseCategory
(
    ExpenseCategoryID  INT IDENTITY(1,1)  NOT NULL,
    CategoryName        NVARCHAR(150)      NOT NULL,
    Description          NVARCHAR(500)      NULL,
    IsActive              BIT                NOT NULL CONSTRAINT DF_ExpenseCategory_IsActive DEFAULT (1),
    CONSTRAINT PK_ExpenseCategory PRIMARY KEY CLUSTERED (ExpenseCategoryID),
    CONSTRAINT UQ_ExpenseCategory_CategoryName UNIQUE (CategoryName)
);
GO

/* =====================================================================
   DailyExpense
   ===================================================================== */
IF OBJECT_ID('dbo.DailyExpense', 'U') IS NOT NULL DROP TABLE dbo.DailyExpense;
GO
CREATE TABLE dbo.DailyExpense
(
    ExpenseID           INT IDENTITY(1,1)  NOT NULL,
    ExpenseDate          DATE               NOT NULL,
    ExpenseCategoryID    INT                NOT NULL,
    Amount                DECIMAL(18,2)      NOT NULL,
    PaymentMode           NVARCHAR(30)       NOT NULL,
    PaidTo                 NVARCHAR(200)      NULL,
    Description            NVARCHAR(500)      NULL,
    CreatedBy              INT                NULL,
    CreatedAt              DATETIME2          NOT NULL CONSTRAINT DF_DailyExpense_CreatedAt DEFAULT (SYSUTCDATETIME()),
    UpdatedAt              DATETIME2          NULL,
    CONSTRAINT PK_DailyExpense PRIMARY KEY CLUSTERED (ExpenseID),
    CONSTRAINT FK_DailyExpense_ExpenseCategory FOREIGN KEY (ExpenseCategoryID) REFERENCES dbo.ExpenseCategory(ExpenseCategoryID),
    CONSTRAINT FK_DailyExpense_Users FOREIGN KEY (CreatedBy) REFERENCES dbo.Users(UserID)
);
GO

/* =====================================================================
   EmployeeWorkLog
   One row per day an employee did paid work. JobType and RouteID are
   independent of each other and of EmployeeMaster — an employee may go
   on any route, do a non-route job (Collection/Loading/Other), or not
   work at all on a given day (simply no row). Every entry with an
   Amount > 0 books a CashLedger 'Cash Out' entry, same as DailyExpense.
   ===================================================================== */
IF OBJECT_ID('dbo.EmployeeWorkLog', 'U') IS NOT NULL DROP TABLE dbo.EmployeeWorkLog;
GO
CREATE TABLE dbo.EmployeeWorkLog
(
    EmployeeWorkLogID  INT IDENTITY(1,1)  NOT NULL,
    WorkDate             DATE               NOT NULL,
    EmployeeID            INT                NOT NULL,
    JobType                NVARCHAR(30)       NOT NULL, -- Supply, Collection, Loading, Other
    RouteID                  INT                NULL,
    Amount                    DECIMAL(18,2)      NOT NULL,
    PaymentMode                NVARCHAR(30)       NOT NULL,
    Remarks                      NVARCHAR(500)      NULL,
    CreatedBy                      INT                NULL,
    CreatedAt                        DATETIME2          NOT NULL CONSTRAINT DF_EmployeeWorkLog_CreatedAt DEFAULT (SYSUTCDATETIME()),
    UpdatedAt                          DATETIME2          NULL,
    CONSTRAINT PK_EmployeeWorkLog PRIMARY KEY CLUSTERED (EmployeeWorkLogID),
    CONSTRAINT FK_EmployeeWorkLog_EmployeeMaster FOREIGN KEY (EmployeeID) REFERENCES dbo.EmployeeMaster(EmployeeID),
    CONSTRAINT FK_EmployeeWorkLog_RouteMaster FOREIGN KEY (RouteID) REFERENCES dbo.RouteMaster(RouteID),
    CONSTRAINT FK_EmployeeWorkLog_Users FOREIGN KEY (CreatedBy) REFERENCES dbo.Users(UserID)
);
GO

/* =====================================================================
   ShopLedger
   ===================================================================== */
IF OBJECT_ID('dbo.ShopLedger', 'U') IS NOT NULL DROP TABLE dbo.ShopLedger;
GO
CREATE TABLE dbo.ShopLedger
(
    LedgerID          BIGINT IDENTITY(1,1) NOT NULL,
    ShopID             INT                  NOT NULL,
    TransactionDate     DATETIME2            NOT NULL,
    TransactionType     NVARCHAR(30)         NOT NULL, -- OpeningBalance, Supply, Collection, Adjustment
    ReferenceID          INT                  NULL,
    Debit                 DECIMAL(18,2)        NOT NULL CONSTRAINT DF_ShopLedger_Debit DEFAULT (0),
    Credit                DECIMAL(18,2)        NOT NULL CONSTRAINT DF_ShopLedger_Credit DEFAULT (0),
    RunningBalance        DECIMAL(18,2)        NOT NULL,
    Narration              NVARCHAR(500)        NULL,
    CreatedAt              DATETIME2            NOT NULL CONSTRAINT DF_ShopLedger_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_ShopLedger PRIMARY KEY CLUSTERED (LedgerID),
    CONSTRAINT FK_ShopLedger_ShopMaster FOREIGN KEY (ShopID) REFERENCES dbo.ShopMaster(ShopID)
);
GO

/* =====================================================================
   SupplierLedger
   ===================================================================== */
IF OBJECT_ID('dbo.SupplierLedger', 'U') IS NOT NULL DROP TABLE dbo.SupplierLedger;
GO
CREATE TABLE dbo.SupplierLedger
(
    LedgerID          BIGINT IDENTITY(1,1) NOT NULL,
    SupplierID          INT                  NOT NULL,
    TransactionDate     DATETIME2            NOT NULL,
    TransactionType     NVARCHAR(30)         NOT NULL, -- OpeningBalance, Purchase, SupplierPayment, Adjustment
    ReferenceID          INT                  NULL,
    Debit                 DECIMAL(18,2)        NOT NULL CONSTRAINT DF_SupplierLedger_Debit DEFAULT (0),
    Credit                DECIMAL(18,2)        NOT NULL CONSTRAINT DF_SupplierLedger_Credit DEFAULT (0),
    RunningBalance        DECIMAL(18,2)        NOT NULL,
    Narration              NVARCHAR(500)        NULL,
    CreatedAt              DATETIME2            NOT NULL CONSTRAINT DF_SupplierLedger_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_SupplierLedger PRIMARY KEY CLUSTERED (LedgerID),
    CONSTRAINT FK_SupplierLedger_SupplierMaster FOREIGN KEY (SupplierID) REFERENCES dbo.SupplierMaster(SupplierID)
);
GO

/* =====================================================================
   StockLedger — tracks fruit stock quantity. Purchase books QuantityIn,
   Supply books QuantityOut, mirroring the Shop/Supplier/Cash ledger
   pattern (including automatic recalculation of RunningStock).
   ===================================================================== */
IF OBJECT_ID('dbo.StockLedger', 'U') IS NOT NULL DROP TABLE dbo.StockLedger;
GO
CREATE TABLE dbo.StockLedger
(
    StockLedgerID    BIGINT IDENTITY(1,1) NOT NULL,
    FruitID           INT                  NOT NULL,
    TransactionDate    DATETIME2            NOT NULL,
    TransactionType    NVARCHAR(30)         NOT NULL, -- Purchase, Supply, Adjustment
    ReferenceTable      NVARCHAR(50)         NOT NULL,
    ReferenceID           INT                  NULL,
    QuantityIn             DECIMAL(18,3)        NOT NULL CONSTRAINT DF_StockLedger_QuantityIn DEFAULT (0),
    QuantityOut             DECIMAL(18,3)        NOT NULL CONSTRAINT DF_StockLedger_QuantityOut DEFAULT (0),
    RunningStock              DECIMAL(18,3)        NOT NULL,
    Narration                  NVARCHAR(500)        NULL,
    CreatedAt                    DATETIME2            NOT NULL CONSTRAINT DF_StockLedger_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_StockLedger PRIMARY KEY CLUSTERED (StockLedgerID),
    CONSTRAINT FK_StockLedger_FruitMaster FOREIGN KEY (FruitID) REFERENCES dbo.FruitMaster(FruitID)
);
GO

/* =====================================================================
   CashLedger
   ===================================================================== */
IF OBJECT_ID('dbo.CashLedger', 'U') IS NOT NULL DROP TABLE dbo.CashLedger;
GO
CREATE TABLE dbo.CashLedger
(
    CashLedgerID     BIGINT IDENTITY(1,1) NOT NULL,
    TransactionDate    DATETIME2            NOT NULL,
    TransactionType    NVARCHAR(30)         NOT NULL, -- OpeningBalance, Collection, SupplierPayment, DailyExpense, Adjustment
    ReferenceTable      NVARCHAR(50)         NOT NULL,
    ReferenceID          INT                  NULL,
    PaymentMode           NVARCHAR(30)         NOT NULL,
    CashIn                 DECIMAL(18,2)        NOT NULL CONSTRAINT DF_CashLedger_CashIn DEFAULT (0),
    CashOut                DECIMAL(18,2)        NOT NULL CONSTRAINT DF_CashLedger_CashOut DEFAULT (0),
    RunningBalance          DECIMAL(18,2)        NOT NULL,
    Narration                NVARCHAR(500)        NULL,
    CreatedAt                DATETIME2            NOT NULL CONSTRAINT DF_CashLedger_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_CashLedger PRIMARY KEY CLUSTERED (CashLedgerID)
);
GO

PRINT 'Tables created successfully.';
GO
