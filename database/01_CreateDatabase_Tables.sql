/* =====================================================================
   Fruit Wholesale Management System
   01_CreateDatabase_Tables.sql
   Creates all core tables, primary keys, foreign keys and default
   constraints. Run against an existing (already-created) database —
   Postgres can't CREATE DATABASE from inside a script running against
   a connection to another database; create FruitWholesaleDB with
   `createdb` / `CREATE DATABASE` from psql first.
   ===================================================================== */

/* =====================================================================
   Drop all tables up front, in dependency-safe (child-before-parent)
   order, so this script can be re-run at any time. Each CREATE TABLE
   section below still guards with IF NOT EXISTS for safety, but relies
   on this block for the correct drop order.
   ===================================================================== */
DROP TABLE IF EXISTS ShopReturnItems;
DROP TABLE IF EXISTS ShopReturns;
DROP TABLE IF EXISTS SupplierReturnItems;
DROP TABLE IF EXISTS SupplierReturns;
DROP TABLE IF EXISTS Collections;
DROP TABLE IF EXISTS TemporaryCollectionSettlements;
DROP TABLE IF EXISTS CashLedger;
DROP TABLE IF EXISTS SupplierLedger;
DROP TABLE IF EXISTS ShopLedger;
DROP TABLE IF EXISTS FruitBoxes;
DROP TABLE IF EXISTS StockLedger;
DROP TABLE IF EXISTS FruitCostLayers;
DROP TABLE IF EXISTS FruitCostBasis;
DROP TABLE IF EXISTS EmployeeWorkLog;
DROP TABLE IF EXISTS DailyExpense;
DROP TABLE IF EXISTS SupplierPayments;
DROP TABLE IF EXISTS PurchaseItems;
DROP TABLE IF EXISTS Purchase;
DROP TABLE IF EXISTS Collections;
DROP TABLE IF EXISTS SupplyItems;
DROP TABLE IF EXISTS Supply;
DROP TABLE IF EXISTS ExpenseCategory;
DROP TABLE IF EXISTS EmployeeMaster;
DROP TABLE IF EXISTS RefreshTokens;
DROP TABLE IF EXISTS SupplierMaster;
DROP TABLE IF EXISTS ShopMaster;
DROP TABLE IF EXISTS RouteMaster;
DROP TABLE IF EXISTS FruitMaster;
DROP TABLE IF EXISTS Users;
DROP TABLE IF EXISTS CompanySettings;

/* =====================================================================
   CompanySettings
   ===================================================================== */
CREATE TABLE CompanySettings
(
    CompanyID           INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    CompanyName         VARCHAR(200)        NOT NULL,
    OwnerName           VARCHAR(150)        NULL,
    Address              VARCHAR(500)       NULL,
    Phone               VARCHAR(20)         NULL,
    GSTNo               VARCHAR(50)         NULL,
    LogoUrl             TEXT                NULL,
    OpeningCashBalance  DECIMAL(18,2)       NOT NULL DEFAULT (0),
    CreatedAt           TIMESTAMP           NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    UpdatedAt           TIMESTAMP           NULL,
    CONSTRAINT PK_CompanySettings PRIMARY KEY (CompanyID)
);

/* =====================================================================
   Users
   ===================================================================== */
CREATE TABLE Users
(
    UserID          INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    FullName        VARCHAR(150)       NOT NULL,
    Username        VARCHAR(100)       NOT NULL,
    PasswordHash    VARCHAR(300)       NOT NULL,
    Role            VARCHAR(50)        NOT NULL, -- Admin, Manager, Accountant, Staff
    IsActive        BOOLEAN            NOT NULL DEFAULT (TRUE),
    CreatedAt       TIMESTAMP          NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    UpdatedAt       TIMESTAMP          NULL,
    CONSTRAINT PK_Users PRIMARY KEY (UserID),
    CONSTRAINT UQ_Users_Username UNIQUE (Username)
);

/* =====================================================================
   RefreshTokens
   ===================================================================== */
CREATE TABLE RefreshTokens
(
    RefreshTokenID       INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    UserID               INT               NOT NULL,
    TokenHash            VARCHAR(128)      NOT NULL,
    ExpiresAt            TIMESTAMP         NOT NULL,
    CreatedAt            TIMESTAMP         NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    RevokedAt            TIMESTAMP         NULL,
    ReplacedByTokenHash  VARCHAR(128)      NULL,
    CONSTRAINT PK_RefreshTokens PRIMARY KEY (RefreshTokenID),
    CONSTRAINT FK_RefreshTokens_Users FOREIGN KEY (UserID) REFERENCES Users(UserID)
);
CREATE INDEX IX_RefreshTokens_TokenHash ON RefreshTokens (TokenHash);
CREATE INDEX IX_RefreshTokens_UserID ON RefreshTokens (UserID);

/* =====================================================================
   FruitMaster
   ===================================================================== */
CREATE TABLE FruitMaster
(
    FruitID     INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    FruitName   VARCHAR(150)       NOT NULL,
    Unit        VARCHAR(20)        NOT NULL, -- Kg, Box, Dozen, Piece
    TracksByBox BOOLEAN            NOT NULL DEFAULT (FALSE),
    BoxWeightKg DECIMAL(18,3)      NULL, -- nominal kg per box
    IsActive    BOOLEAN            NOT NULL DEFAULT (TRUE),
    CreatedAt   TIMESTAMP          NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    UpdatedAt   TIMESTAMP          NULL,
    CONSTRAINT PK_FruitMaster PRIMARY KEY (FruitID),
    CONSTRAINT UQ_FruitMaster_FruitName UNIQUE (FruitName)
);

/* =====================================================================
   FruitCostBasis (weighted-average cost tracking for profit calculation)
   ===================================================================== */
CREATE TABLE FruitCostBasis
(
    FruitID          INT            NOT NULL,
    QuantityOnHand   DECIMAL(18,3)  NOT NULL DEFAULT (0),
    AverageCost      DECIMAL(18,4)  NOT NULL DEFAULT (0),
    UpdatedAt        TIMESTAMP      NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    CONSTRAINT PK_FruitCostBasis PRIMARY KEY (FruitID),
    CONSTRAINT FK_FruitCostBasis_FruitMaster FOREIGN KEY (FruitID) REFERENCES FruitMaster(FruitID)
);

/* =====================================================================
   FruitCostLayers (FIFO queue of remaining purchase/return batches per
   fruit — rebuilt from scratch on every cost-basis recalculation)
   ===================================================================== */
CREATE TABLE FruitCostLayers
(
    FruitCostLayerID  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    FruitID           INT            NOT NULL,
    SourceType        VARCHAR(20)    NOT NULL,
    SourceItemID      INT            NOT NULL,
    TransactionDate   DATE           NOT NULL,
    UnitCost          DECIMAL(18,4)  NOT NULL,
    RemainingQuantity DECIMAL(18,3)  NOT NULL,
    CreatedAt         TIMESTAMP      NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    CONSTRAINT FK_FruitCostLayers_FruitMaster FOREIGN KEY (FruitID) REFERENCES FruitMaster(FruitID)
);
CREATE INDEX IX_FruitCostLayers_FruitID ON FruitCostLayers(FruitID);

/* =====================================================================
   RouteMaster (a supply route groups a set of shops that share a
   delivery run — a wholesaler may run more than one route)
   ===================================================================== */
CREATE TABLE RouteMaster
(
    RouteID     INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    RouteName   VARCHAR(150)       NOT NULL,
    Description VARCHAR(500)       NULL,
    IsActive    BOOLEAN            NOT NULL DEFAULT (TRUE),
    CreatedAt   TIMESTAMP          NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    UpdatedAt   TIMESTAMP          NULL,
    CONSTRAINT PK_RouteMaster PRIMARY KEY (RouteID),
    CONSTRAINT UQ_RouteMaster_RouteName UNIQUE (RouteName)
);

/* =====================================================================
   ShopMaster (Customers)
   ===================================================================== */
CREATE TABLE ShopMaster
(
    ShopID          INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    ShopName        VARCHAR(200)       NOT NULL,
    OwnerName       VARCHAR(150)       NULL,
    Phone           VARCHAR(20)        NULL,
    Address         VARCHAR(500)       NULL,
    OpeningBalance  DECIMAL(18,2)      NOT NULL DEFAULT (0),
    CreditLimit     DECIMAL(18,2)      NOT NULL DEFAULT (0),
    RouteID         INT                NULL,
    LinkedSupplierID INT               NULL,
    IsActive        BOOLEAN            NOT NULL DEFAULT (TRUE),
    CreatedAt       TIMESTAMP          NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    UpdatedAt       TIMESTAMP          NULL,
    CONSTRAINT PK_ShopMaster PRIMARY KEY (ShopID),
    CONSTRAINT FK_ShopMaster_RouteMaster FOREIGN KEY (RouteID) REFERENCES RouteMaster(RouteID)
    -- FK_ShopMaster_SupplierMaster added below, after SupplierMaster exists.
);

/* =====================================================================
   SupplierMaster
   ===================================================================== */
CREATE TABLE SupplierMaster
(
    SupplierID      INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    SupplierName    VARCHAR(200)       NOT NULL,
    Phone           VARCHAR(20)        NULL,
    Address         VARCHAR(500)       NULL,
    OpeningBalance  DECIMAL(18,2)      NOT NULL DEFAULT (0),
    IsActive        BOOLEAN            NOT NULL DEFAULT (TRUE),
    CreatedAt       TIMESTAMP          NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    UpdatedAt       TIMESTAMP          NULL,
    CONSTRAINT PK_SupplierMaster PRIMARY KEY (SupplierID)
);

ALTER TABLE ShopMaster ADD CONSTRAINT FK_ShopMaster_SupplierMaster
    FOREIGN KEY (LinkedSupplierID) REFERENCES SupplierMaster(SupplierID);

/* =====================================================================
   EmployeeMaster
   A plain staff directory — employees have no fixed route or fixed
   working days. Which route (if any) and what job they did on a given
   day, and what they were paid for it, is recorded per entry in
   EmployeeWorkLog below.
   ===================================================================== */
CREATE TABLE EmployeeMaster
(
    EmployeeID  INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    FullName    VARCHAR(150)       NOT NULL,
    Phone       VARCHAR(20)        NULL,
    Address     VARCHAR(500)       NULL,
    IsActive    BOOLEAN            NOT NULL DEFAULT (TRUE),
    CreatedAt   TIMESTAMP          NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    UpdatedAt   TIMESTAMP          NULL,
    CONSTRAINT PK_EmployeeMaster PRIMARY KEY (EmployeeID)
);

/* =====================================================================
   Supply (header) + SupplyItems
   ===================================================================== */
CREATE TABLE Supply
(
    SupplyID     INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    SupplyDate   DATE               NOT NULL,
    ShopID       INT                NOT NULL,
    InvoiceNo    VARCHAR(50)        NOT NULL,
    Remarks      VARCHAR(500)       NULL,
    TotalAmount  DECIMAL(18,2)      NOT NULL DEFAULT (0),
    CreatedBy    INT                NULL,
    CreatedAt    TIMESTAMP          NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    UpdatedAt    TIMESTAMP          NULL,
    CONSTRAINT PK_Supply PRIMARY KEY (SupplyID),
    CONSTRAINT UQ_Supply_InvoiceNo UNIQUE (InvoiceNo),
    CONSTRAINT FK_Supply_ShopMaster FOREIGN KEY (ShopID) REFERENCES ShopMaster(ShopID),
    CONSTRAINT FK_Supply_Users FOREIGN KEY (CreatedBy) REFERENCES Users(UserID)
);
CREATE TABLE SupplyItems
(
    SupplyItemID  INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    SupplyID      INT                NOT NULL,
    FruitID       INT                NOT NULL,
    Quantity      DECIMAL(18,3)      NOT NULL,
    UnitPrice     DECIMAL(18,2)      NOT NULL,
    TotalAmount   DECIMAL(18,2)      NOT NULL,
    CostBasis     DECIMAL(18,4)      NOT NULL DEFAULT (0), -- weighted-avg fruit cost at time of sale
    BoxCount      DECIMAL(18,3)      NULL, -- display-only box count for "by box" sales
    CONSTRAINT PK_SupplyItems PRIMARY KEY (SupplyItemID),
    CONSTRAINT FK_SupplyItems_Supply FOREIGN KEY (SupplyID) REFERENCES Supply(SupplyID) ON DELETE CASCADE,
    CONSTRAINT FK_SupplyItems_FruitMaster FOREIGN KEY (FruitID) REFERENCES FruitMaster(FruitID)
);

/* =====================================================================
   TemporaryCollectionSettlements — a batch settlement of a shop's
   pending "Temporary" collections (money collected but not yet booked
   to the shop ledger) into a single dated ShopLedger credit.
   ===================================================================== */
CREATE TABLE TemporaryCollectionSettlements
(
    TemporaryCollectionSettlementID INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    ShopID           INT               NOT NULL,
    SettlementDate   DATE              NOT NULL,
    TotalAmount      DECIMAL(18,2)     NOT NULL,
    CreatedBy        INT               NULL,
    CreatedAt        TIMESTAMP         NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    CONSTRAINT PK_TemporaryCollectionSettlements PRIMARY KEY (TemporaryCollectionSettlementID),
    CONSTRAINT FK_TemporaryCollectionSettlements_ShopMaster FOREIGN KEY (ShopID) REFERENCES ShopMaster(ShopID),
    CONSTRAINT FK_TemporaryCollectionSettlements_Users FOREIGN KEY (CreatedBy) REFERENCES Users(UserID)
);

/* =====================================================================
   Collections
   ===================================================================== */
CREATE TABLE Collections
(
    CollectionID     INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    CollectionDate   DATE               NOT NULL,
    ShopID           INT                NOT NULL,
    AmountReceived   DECIMAL(18,2)      NOT NULL,
    DiscountAmount   DECIMAL(18,2)      NOT NULL DEFAULT (0),
    PaymentMode      VARCHAR(30)        NOT NULL, -- Cash, Bank, UPI, Cheque
    ReferenceNumber  VARCHAR(100)       NULL,
    Remarks          VARCHAR(500)       NULL,
    CreatedBy        INT                NULL,
    CreatedAt        TIMESTAMP          NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    UpdatedAt        TIMESTAMP          NULL,
    CollectionType   VARCHAR(20)        NULL, -- Normal, Temporary
    TemporaryStatus  VARCHAR(20)        NOT NULL DEFAULT ('None'), -- None, Pending, Settled
    SettlementID     INT                NULL,
    CONSTRAINT PK_Collections PRIMARY KEY (CollectionID),
    CONSTRAINT FK_Collections_ShopMaster FOREIGN KEY (ShopID) REFERENCES ShopMaster(ShopID),
    CONSTRAINT FK_Collections_Users FOREIGN KEY (CreatedBy) REFERENCES Users(UserID),
    CONSTRAINT FK_Collections_TemporaryCollectionSettlements FOREIGN KEY (SettlementID) REFERENCES TemporaryCollectionSettlements(TemporaryCollectionSettlementID)
);

/* =====================================================================
   Purchase (header) + PurchaseItems
   ===================================================================== */
CREATE TABLE Purchase
(
    PurchaseID   INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    PurchaseDate DATE               NOT NULL,
    SupplierID   INT                NOT NULL,
    InvoiceNo    VARCHAR(50)        NOT NULL,
    Remarks      VARCHAR(500)       NULL,
    TotalAmount  DECIMAL(18,2)      NOT NULL DEFAULT (0),
    CreatedBy    INT                NULL,
    CreatedAt    TIMESTAMP          NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    UpdatedAt    TIMESTAMP          NULL,
    CONSTRAINT PK_Purchase PRIMARY KEY (PurchaseID),
    CONSTRAINT UQ_Purchase_InvoiceNo UNIQUE (InvoiceNo),
    CONSTRAINT FK_Purchase_SupplierMaster FOREIGN KEY (SupplierID) REFERENCES SupplierMaster(SupplierID),
    CONSTRAINT FK_Purchase_Users FOREIGN KEY (CreatedBy) REFERENCES Users(UserID)
);
CREATE TABLE PurchaseItems
(
    PurchaseItemID  INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    PurchaseID      INT                NOT NULL,
    FruitID         INT                NOT NULL,
    Quantity        DECIMAL(18,3)      NOT NULL,
    PurchasePrice   DECIMAL(18,2)      NOT NULL,
    TotalAmount     DECIMAL(18,2)      NOT NULL,
    BoxCount        DECIMAL(18,3)      NULL, -- physical box count for TracksByBox fruits
    CONSTRAINT PK_PurchaseItems PRIMARY KEY (PurchaseItemID),
    CONSTRAINT FK_PurchaseItems_Purchase FOREIGN KEY (PurchaseID) REFERENCES Purchase(PurchaseID) ON DELETE CASCADE,
    CONSTRAINT FK_PurchaseItems_FruitMaster FOREIGN KEY (FruitID) REFERENCES FruitMaster(FruitID)
);

/* =====================================================================
   SupplierPayments
   ===================================================================== */
CREATE TABLE SupplierPayments
(
    SupplierPaymentID  INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    PaymentDate         DATE               NOT NULL,
    SupplierID           INT                NOT NULL,
    AmountPaid           DECIMAL(18,2)      NOT NULL,
    DiscountAmount        DECIMAL(18,2)      NOT NULL DEFAULT (0),
    PaymentMode          VARCHAR(30)        NOT NULL,
    ReferenceNumber      VARCHAR(100)       NULL,
    Remarks               VARCHAR(500)      NULL,
    CreatedBy             INT               NULL,
    CreatedAt             TIMESTAMP         NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    UpdatedAt             TIMESTAMP         NULL,
    CONSTRAINT PK_SupplierPayments PRIMARY KEY (SupplierPaymentID),
    CONSTRAINT FK_SupplierPayments_SupplierMaster FOREIGN KEY (SupplierID) REFERENCES SupplierMaster(SupplierID),
    CONSTRAINT FK_SupplierPayments_Users FOREIGN KEY (CreatedBy) REFERENCES Users(UserID)
);

/* =====================================================================
   ExpenseCategory
   ===================================================================== */
CREATE TABLE ExpenseCategory
(
    ExpenseCategoryID  INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    CategoryName        VARCHAR(150)      NOT NULL,
    Description          VARCHAR(500)     NULL,
    IsActive              BOOLEAN         NOT NULL DEFAULT (TRUE),
    CONSTRAINT PK_ExpenseCategory PRIMARY KEY (ExpenseCategoryID),
    CONSTRAINT UQ_ExpenseCategory_CategoryName UNIQUE (CategoryName)
);

/* =====================================================================
   DailyExpense
   ===================================================================== */
CREATE TABLE DailyExpense
(
    ExpenseID           INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    ExpenseDate          DATE              NOT NULL,
    ExpenseCategoryID    INT               NOT NULL,
    Amount                DECIMAL(18,2)    NOT NULL,
    PaymentMode           VARCHAR(30)      NOT NULL,
    PaidTo                 VARCHAR(200)    NULL,
    Description            VARCHAR(500)    NULL,
    CreatedBy              INT             NULL,
    CreatedAt              TIMESTAMP       NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    UpdatedAt              TIMESTAMP       NULL,
    CONSTRAINT PK_DailyExpense PRIMARY KEY (ExpenseID),
    CONSTRAINT FK_DailyExpense_ExpenseCategory FOREIGN KEY (ExpenseCategoryID) REFERENCES ExpenseCategory(ExpenseCategoryID),
    CONSTRAINT FK_DailyExpense_Users FOREIGN KEY (CreatedBy) REFERENCES Users(UserID)
);

/* =====================================================================
   EmployeeWorkLog
   One row per day an employee did paid work. JobType and RouteID are
   independent of each other and of EmployeeMaster — an employee may go
   on any route, do a non-route job (Collection/Loading/Other), or not
   work at all on a given day (simply no row). Every entry with an
   Amount > 0 books a CashLedger 'Cash Out' entry, same as DailyExpense.
   ===================================================================== */
CREATE TABLE EmployeeWorkLog
(
    EmployeeWorkLogID  INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    WorkDate             DATE            NOT NULL,
    EmployeeID            INT            NOT NULL,
    JobType                VARCHAR(30)   NOT NULL, -- Supply, Collection, Loading, Other
    RouteID                  INT         NULL,
    Amount                    DECIMAL(18,2) NOT NULL,
    PaymentMode                VARCHAR(30) NOT NULL,
    Remarks                      VARCHAR(500) NULL,
    CreatedBy                      INT     NULL,
    CreatedAt                        TIMESTAMP NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    UpdatedAt                          TIMESTAMP NULL,
    CONSTRAINT PK_EmployeeWorkLog PRIMARY KEY (EmployeeWorkLogID),
    CONSTRAINT FK_EmployeeWorkLog_EmployeeMaster FOREIGN KEY (EmployeeID) REFERENCES EmployeeMaster(EmployeeID),
    CONSTRAINT FK_EmployeeWorkLog_RouteMaster FOREIGN KEY (RouteID) REFERENCES RouteMaster(RouteID),
    CONSTRAINT FK_EmployeeWorkLog_Users FOREIGN KEY (CreatedBy) REFERENCES Users(UserID)
);

/* =====================================================================
   ShopLedger
   ===================================================================== */
CREATE TABLE ShopLedger
(
    LedgerID          BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL,
    ShopID             INT                 NOT NULL,
    TransactionDate     TIMESTAMP          NOT NULL,
    TransactionType     VARCHAR(30)        NOT NULL, -- OpeningBalance, Supply, Collection, Adjustment
    ReferenceID          INT                NULL,
    Debit                 DECIMAL(18,2)     NOT NULL DEFAULT (0),
    Credit                DECIMAL(18,2)     NOT NULL DEFAULT (0),
    RunningBalance        DECIMAL(18,2)     NOT NULL,
    Narration              VARCHAR(500)     NULL,
    CreatedAt              TIMESTAMP        NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    CONSTRAINT PK_ShopLedger PRIMARY KEY (LedgerID),
    CONSTRAINT FK_ShopLedger_ShopMaster FOREIGN KEY (ShopID) REFERENCES ShopMaster(ShopID)
);

/* =====================================================================
   SupplierLedger
   ===================================================================== */
CREATE TABLE SupplierLedger
(
    LedgerID          BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL,
    SupplierID          INT               NOT NULL,
    TransactionDate     TIMESTAMP         NOT NULL,
    TransactionType     VARCHAR(30)       NOT NULL, -- OpeningBalance, Purchase, SupplierPayment, Adjustment
    ReferenceID          INT              NULL,
    Debit                 DECIMAL(18,2)   NOT NULL DEFAULT (0),
    Credit                DECIMAL(18,2)   NOT NULL DEFAULT (0),
    RunningBalance        DECIMAL(18,2)   NOT NULL,
    Narration              VARCHAR(500)   NULL,
    CreatedAt              TIMESTAMP      NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    CONSTRAINT PK_SupplierLedger PRIMARY KEY (LedgerID),
    CONSTRAINT FK_SupplierLedger_SupplierMaster FOREIGN KEY (SupplierID) REFERENCES SupplierMaster(SupplierID)
);

/* =====================================================================
   StockLedger — tracks fruit stock quantity. Purchase books QuantityIn,
   Supply books QuantityOut, mirroring the Shop/Supplier/Cash ledger
   pattern (including automatic recalculation of RunningStock).
   ===================================================================== */
CREATE TABLE StockLedger
(
    StockLedgerID    BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL,
    FruitID           INT                NOT NULL,
    TransactionDate    TIMESTAMP         NOT NULL,
    TransactionType    VARCHAR(30)       NOT NULL, -- Purchase, Supply, Adjustment
    ReferenceTable      VARCHAR(50)      NOT NULL,
    ReferenceID           INT             NULL,
    QuantityIn             DECIMAL(18,3) NOT NULL DEFAULT (0),
    QuantityOut             DECIMAL(18,3) NOT NULL DEFAULT (0),
    RunningStock              DECIMAL(18,3) NOT NULL,
    Narration                  VARCHAR(500) NULL,
    CreatedAt                    TIMESTAMP  NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    CONSTRAINT PK_StockLedger PRIMARY KEY (StockLedgerID),
    CONSTRAINT FK_StockLedger_FruitMaster FOREIGN KEY (FruitID) REFERENCES FruitMaster(FruitID)
);

/* =====================================================================
   FruitBoxes — dual-unit (box count + kg) tracking layer for
   TracksByBox fruits, on top of StockLedger's kg-only tracking. One row
   per physical box; rebuilt from scratch by
   LedgerService.RecalculateFruitBoxesAsync on every Purchase/Supply
   write.
   ===================================================================== */
CREATE TABLE FruitBoxes
(
    FruitBoxID         INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    FruitID            INT               NOT NULL,
    PurchaseID         INT               NULL,
    InitialWeightKg    DECIMAL(18,3)     NOT NULL,
    RemainingWeightKg  DECIMAL(18,3)     NOT NULL,
    Status             VARCHAR(10)       NOT NULL, -- Full | Opened | Empty
    CreatedAt          TIMESTAMP         NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    UpdatedAt          TIMESTAMP         NULL,
    CONSTRAINT PK_FruitBoxes PRIMARY KEY (FruitBoxID),
    CONSTRAINT FK_FruitBoxes_FruitMaster FOREIGN KEY (FruitID) REFERENCES FruitMaster(FruitID),
    CONSTRAINT FK_FruitBoxes_Purchase FOREIGN KEY (PurchaseID) REFERENCES Purchase(PurchaseID) ON DELETE SET NULL
);
CREATE INDEX IX_FruitBoxes_FruitID_Status ON FruitBoxes (FruitID, Status) INCLUDE (RemainingWeightKg);

/* =====================================================================
   CashLedger
   ===================================================================== */
CREATE TABLE CashLedger
(
    CashLedgerID     BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL,
    TransactionDate    TIMESTAMP        NOT NULL,
    TransactionType    VARCHAR(30)      NOT NULL, -- OpeningBalance, Collection, SupplierPayment, DailyExpense, Adjustment
    ReferenceTable      VARCHAR(50)     NOT NULL,
    ReferenceID          INT            NULL,
    PaymentMode           VARCHAR(30)   NOT NULL,
    CashIn                 DECIMAL(18,2) NOT NULL DEFAULT (0),
    CashOut                DECIMAL(18,2) NOT NULL DEFAULT (0),
    RunningBalance          DECIMAL(18,2) NOT NULL,
    Narration                VARCHAR(500) NULL,
    CreatedAt                TIMESTAMP    NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    CONSTRAINT PK_CashLedger PRIMARY KEY (CashLedgerID)
);

/* =====================================================================
   ShopReturns / SupplierReturns — returns are their own dated
   documents, not edits to the original invoice. FKs to Supply/Purchase
   are ON DELETE SET NULL: the link is optional traceability, so
   deleting the original invoice must not block deleting/keeping the
   return.
   ===================================================================== */
CREATE TABLE ShopReturns
(
    ShopReturnID    INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    ReturnDate      DATE               NOT NULL,
    ShopID          INT                NOT NULL,
    SupplyID        INT                NULL,
    ReferenceNo     VARCHAR(50)        NOT NULL,
    Remarks         VARCHAR(500)       NULL,
    TotalAmount     DECIMAL(18,2)      NOT NULL DEFAULT (0),
    CreatedBy       INT                NULL,
    CreatedAt       TIMESTAMP          NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    UpdatedAt       TIMESTAMP          NULL,
    CONSTRAINT PK_ShopReturns PRIMARY KEY (ShopReturnID),
    CONSTRAINT UQ_ShopReturns_ReferenceNo UNIQUE (ReferenceNo),
    CONSTRAINT FK_ShopReturns_ShopMaster FOREIGN KEY (ShopID) REFERENCES ShopMaster(ShopID),
    CONSTRAINT FK_ShopReturns_Supply FOREIGN KEY (SupplyID) REFERENCES Supply(SupplyID) ON DELETE SET NULL,
    CONSTRAINT FK_ShopReturns_Users FOREIGN KEY (CreatedBy) REFERENCES Users(UserID)
);

CREATE TABLE ShopReturnItems
(
    ShopReturnItemID INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    ShopReturnID      INT               NOT NULL,
    FruitID           INT               NOT NULL,
    Quantity          DECIMAL(18,3)     NOT NULL,
    UnitPrice         DECIMAL(18,2)     NOT NULL,
    TotalAmount       DECIMAL(18,2)     NOT NULL,
    CostBasis         DECIMAL(18,4)     NOT NULL DEFAULT (0),
    BoxCount          DECIMAL(18,3)     NULL,
    CONSTRAINT PK_ShopReturnItems PRIMARY KEY (ShopReturnItemID),
    CONSTRAINT FK_ShopReturnItems_ShopReturns FOREIGN KEY (ShopReturnID) REFERENCES ShopReturns(ShopReturnID) ON DELETE CASCADE,
    CONSTRAINT FK_ShopReturnItems_FruitMaster FOREIGN KEY (FruitID) REFERENCES FruitMaster(FruitID)
);

CREATE TABLE SupplierReturns
(
    SupplierReturnID INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    ReturnDate        DATE               NOT NULL,
    SupplierID        INT                NOT NULL,
    PurchaseID        INT                NULL,
    ReferenceNo       VARCHAR(50)        NOT NULL,
    Remarks           VARCHAR(500)       NULL,
    TotalAmount       DECIMAL(18,2)      NOT NULL DEFAULT (0),
    CreatedBy         INT                NULL,
    CreatedAt         TIMESTAMP          NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    UpdatedAt         TIMESTAMP          NULL,
    CONSTRAINT PK_SupplierReturns PRIMARY KEY (SupplierReturnID),
    CONSTRAINT UQ_SupplierReturns_ReferenceNo UNIQUE (ReferenceNo),
    CONSTRAINT FK_SupplierReturns_SupplierMaster FOREIGN KEY (SupplierID) REFERENCES SupplierMaster(SupplierID),
    CONSTRAINT FK_SupplierReturns_Purchase FOREIGN KEY (PurchaseID) REFERENCES Purchase(PurchaseID) ON DELETE SET NULL,
    CONSTRAINT FK_SupplierReturns_Users FOREIGN KEY (CreatedBy) REFERENCES Users(UserID)
);

CREATE TABLE SupplierReturnItems
(
    SupplierReturnItemID INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    SupplierReturnID      INT               NOT NULL,
    FruitID                INT              NOT NULL,
    Quantity               DECIMAL(18,3)    NOT NULL,
    UnitPrice              DECIMAL(18,2)    NOT NULL,
    TotalAmount            DECIMAL(18,2)    NOT NULL,
    CostBasis              DECIMAL(18,4)    NOT NULL DEFAULT (0),
    BoxCount               DECIMAL(18,3)    NULL,
    CONSTRAINT PK_SupplierReturnItems PRIMARY KEY (SupplierReturnItemID),
    CONSTRAINT FK_SupplierReturnItems_SupplierReturns FOREIGN KEY (SupplierReturnID) REFERENCES SupplierReturns(SupplierReturnID) ON DELETE CASCADE,
    CONSTRAINT FK_SupplierReturnItems_FruitMaster FOREIGN KEY (FruitID) REFERENCES FruitMaster(FruitID)
);
