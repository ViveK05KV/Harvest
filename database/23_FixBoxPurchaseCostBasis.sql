/* =====================================================================
   Fruit Wholesale Management System
   23_FixBoxPurchaseCostBasis.sql

   Bug: RecalculateFruitCostBasisAsync used PurchaseItems.PurchasePrice
   directly as the per-kg unit cost feeding the weighted-average cost
   basis. For box-tracked fruits, PurchasePrice is entered per BOX (e.g.
   3550/box), not per kg, while Quantity is always in kg - so a box
   purchase's cost got blended in at the per-box rate applied to every
   kg, inflating cost basis by roughly the box weight (18x for an 18kg
   box). Revenue was unaffected; only Cost/Profit/Margin were wrong, and
   only for box-tracked fruits. Confirmed on production: Apple
   NewZealand Gala showed cost = 63900 for 18kg sold, i.e. 3550/kg -
   exactly the box rate used as a per-kg rate.

   Fix: the application code now uses TotalAmount/Quantity (always a
   true per-kg cost, since TotalAmount is already correctly
   BoxCount*PurchasePrice or Quantity*PurchasePrice - see
   LedgerService.RecalculateFruitCostBasisAsync). That only corrects
   future recalculations, so this script replays the full purchase/
   supply/shop-return/supplier-return history for every fruit, in
   chronological order, with the corrected formula, and rewrites every
   already-stored CostBasis value (SupplyItems, SupplierReturnItems,
   ShopReturnItems) and FruitCostBasis - mirroring
   RecalculateFruitCostBasisAsync exactly, including how a Shop Return's
   CostBasis is resolved (the linked Supply's CostBasis if the return is
   tied to a specific invoice that had this fruit on it, otherwise
   whatever the running average is at that point in the replay - see
   ShopReturnRepository.ResolveReturnCostBasisBatchAsync for the
   original, now-corrected-inputs version of this same rule).

   Idempotent - safe to re-run against a live database; each run fully
   replaces the derived values from scratch.
   ===================================================================== */
USE FruitWholesaleDB;
GO

DECLARE @FruitID INT;
DECLARE @QuantityOnHand DECIMAL(18,4);
DECLARE @AverageCost DECIMAL(18,4);

DECLARE @EventType VARCHAR(20);
DECLARE @ItemID INT;
DECLARE @TransactionDate DATETIME2;
DECLARE @ParentCreatedAt DATETIME2;
DECLARE @Quantity DECIMAL(18,4);
DECLARE @PurchaseUnitCost DECIMAL(18,4);
DECLARE @LinkedSupplyID INT;
DECLARE @ReturnUnitCost DECIMAL(18,4);
DECLARE @NewQuantity DECIMAL(18,4);

DECLARE fruit_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT FruitID FROM dbo.FruitMaster;

OPEN fruit_cursor;
FETCH NEXT FROM fruit_cursor INTO @FruitID;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @QuantityOnHand = 0;
    SET @AverageCost = 0;

    DECLARE event_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT 'PURCHASE' AS EventType, pi.PurchaseItemID AS ItemID, p.PurchaseDate AS TransactionDate,
               p.CreatedAt AS ParentCreatedAt, pi.Quantity, pi.TotalAmount / pi.Quantity AS UnitCost,
               CAST(NULL AS INT) AS LinkedSupplyID
        FROM dbo.PurchaseItems pi
        INNER JOIN dbo.Purchase p ON p.PurchaseID = pi.PurchaseID
        WHERE pi.FruitID = @FruitID

        UNION ALL

        SELECT 'SHOP_RETURN', sri.ShopReturnItemID, sr.ReturnDate, sr.CreatedAt, sri.Quantity, NULL, sr.SupplyID
        FROM dbo.ShopReturnItems sri
        INNER JOIN dbo.ShopReturns sr ON sr.ShopReturnID = sri.ShopReturnID
        WHERE sri.FruitID = @FruitID

        UNION ALL

        SELECT 'SUPPLY', si.SupplyItemID, s.SupplyDate, s.CreatedAt, si.Quantity, NULL, NULL
        FROM dbo.SupplyItems si
        INNER JOIN dbo.Supply s ON s.SupplyID = si.SupplyID
        WHERE si.FruitID = @FruitID

        UNION ALL

        SELECT 'SUPPLIER_RETURN', sri2.SupplierReturnItemID, sr2.ReturnDate, sr2.CreatedAt, sri2.Quantity, NULL, NULL
        FROM dbo.SupplierReturnItems sri2
        INNER JOIN dbo.SupplierReturns sr2 ON sr2.SupplierReturnID = sri2.SupplierReturnID
        WHERE sri2.FruitID = @FruitID

        ORDER BY TransactionDate ASC, ParentCreatedAt ASC, ItemID ASC;

    OPEN event_cursor;
    FETCH NEXT FROM event_cursor INTO @EventType, @ItemID, @TransactionDate, @ParentCreatedAt, @Quantity, @PurchaseUnitCost, @LinkedSupplyID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @EventType = 'PURCHASE'
        BEGIN
            SET @NewQuantity = @QuantityOnHand + @Quantity;
            SET @AverageCost = CASE WHEN @NewQuantity > 0
                THEN (@QuantityOnHand * @AverageCost + @Quantity * @PurchaseUnitCost) / @NewQuantity
                ELSE 0 END;
            SET @QuantityOnHand = @NewQuantity;
        END
        ELSE IF @EventType = 'SHOP_RETURN'
        BEGIN
            SET @ReturnUnitCost = NULL;
            IF @LinkedSupplyID IS NOT NULL
                SELECT @ReturnUnitCost = CostBasis FROM dbo.SupplyItems WHERE SupplyID = @LinkedSupplyID AND FruitID = @FruitID;
            IF @ReturnUnitCost IS NULL SET @ReturnUnitCost = @AverageCost;

            UPDATE dbo.ShopReturnItems SET CostBasis = @ReturnUnitCost WHERE ShopReturnItemID = @ItemID;

            SET @NewQuantity = @QuantityOnHand + @Quantity;
            SET @AverageCost = CASE WHEN @NewQuantity > 0
                THEN (@QuantityOnHand * @AverageCost + @Quantity * @ReturnUnitCost) / @NewQuantity
                ELSE 0 END;
            SET @QuantityOnHand = @NewQuantity;
        END
        ELSE IF @EventType = 'SUPPLY'
        BEGIN
            UPDATE dbo.SupplyItems SET CostBasis = @AverageCost WHERE SupplyItemID = @ItemID;
            SET @QuantityOnHand = @QuantityOnHand - @Quantity;
        END
        ELSE -- SUPPLIER_RETURN
        BEGIN
            UPDATE dbo.SupplierReturnItems SET CostBasis = @AverageCost WHERE SupplierReturnItemID = @ItemID;
            SET @QuantityOnHand = @QuantityOnHand - @Quantity;
        END

        FETCH NEXT FROM event_cursor INTO @EventType, @ItemID, @TransactionDate, @ParentCreatedAt, @Quantity, @PurchaseUnitCost, @LinkedSupplyID;
    END

    CLOSE event_cursor;
    DEALLOCATE event_cursor;

    IF EXISTS (SELECT 1 FROM dbo.FruitCostBasis WHERE FruitID = @FruitID)
        UPDATE dbo.FruitCostBasis SET QuantityOnHand = @QuantityOnHand, AverageCost = @AverageCost, UpdatedAt = SYSUTCDATETIME()
        WHERE FruitID = @FruitID;
    ELSE
        INSERT INTO dbo.FruitCostBasis (FruitID, QuantityOnHand, AverageCost, UpdatedAt)
        VALUES (@FruitID, @QuantityOnHand, @AverageCost, SYSUTCDATETIME());

    FETCH NEXT FROM fruit_cursor INTO @FruitID;
END

CLOSE fruit_cursor;
DEALLOCATE fruit_cursor;

PRINT 'Cost basis recomputed for every fruit with the box-purchase-price fix applied.';
GO
