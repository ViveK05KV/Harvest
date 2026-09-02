/* =====================================================================
   Fruit Wholesale Management System
   30_SwitchToFifoCostBasis.sql

   Adds FruitCostLayers: a FIFO queue of remaining purchase/return batches
   per fruit, rebuilt from scratch on every RecalculateFruitCostBasisAsync
   run - same "delete-all, replay, reinsert current state" idiom already
   used for FruitBoxes. Powers the switch of the profit-costing engine
   from weighted-average to FIFO (oldest stock sold first).

   FruitCostBasis (FruitID, QuantityOnHand, AverageCost) is unchanged in
   shape - AverageCost now holds the weighted average of whatever layers
   are currently remaining (current stock's blended cost) rather than an
   all-time blend, so ShopReturnRepository's fallback read of it needs no
   code changes.

   Idempotent - safe to re-run.
   ===================================================================== */

CREATE TABLE IF NOT EXISTS FruitCostLayers
(
    FruitCostLayerID  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    FruitID           INT NOT NULL REFERENCES FruitMaster(FruitID),
    SourceType        VARCHAR(20) NOT NULL,
    SourceItemID      INT NOT NULL,
    TransactionDate   DATE NOT NULL,
    UnitCost          DECIMAL(18,4) NOT NULL,
    RemainingQuantity DECIMAL(18,3) NOT NULL,
    CreatedAt         TIMESTAMP NOT NULL DEFAULT (now() AT TIME ZONE 'utc')
);

CREATE INDEX IF NOT EXISTS IX_FruitCostLayers_FruitID ON FruitCostLayers(FruitID);
