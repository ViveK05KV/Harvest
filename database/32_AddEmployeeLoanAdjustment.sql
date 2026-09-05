/* =====================================================================
   Fruit Wholesale Management System
   32_AddEmployeeLoanAdjustment.sql

   Adds EmployeeLoanAdjustment - a manual correction to an employee's
   outstanding loan, mirroring the Adjustment TransactionType already used
   on ShopLedger/SupplierLedger/CashLedger (see ShopMasterService.
   ApplyBalanceAdjustmentAsync for the pattern this follows).

   Unlike EmployeeLoanRepayment, an adjustment does NOT post to CashLedger -
   no real cash moves, it's a pure bookkeeping reclassification (e.g.
   transferring a balance from elsewhere into this employee's loan). Signed
   by IsIncrease rather than separate Debit/Credit columns, since there's
   no running-balance column to maintain here - the loan total is still
   computed live by EmployeeLoanService, this table just adds one more term
   to that computation.

   Idempotent - safe to re-run.
   ===================================================================== */

CREATE TABLE IF NOT EXISTS EmployeeLoanAdjustment
(
    EmployeeLoanAdjustmentID BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    EmployeeID               INT NOT NULL REFERENCES EmployeeMaster(EmployeeID),
    AdjustmentDate           DATE NOT NULL,
    Amount                   DECIMAL(18,2) NOT NULL,
    IsIncrease               BOOLEAN NOT NULL,
    Narration                VARCHAR(500) NOT NULL,
    CreatedBy                INT NULL,
    CreatedAt                TIMESTAMP NOT NULL DEFAULT (now() AT TIME ZONE 'utc')
);

CREATE INDEX IF NOT EXISTS IX_EmployeeLoanAdjustment_EmployeeID ON EmployeeLoanAdjustment(EmployeeID);
