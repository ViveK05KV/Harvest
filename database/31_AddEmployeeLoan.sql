/* =====================================================================
   Fruit Wholesale Management System
   31_AddEmployeeLoan.sql

   Adds employee pay-rate configuration (SalaryType/SalaryAmount on
   EmployeeMaster) and EmployeeLoanRepayment, a simple event log of cash an
   employee has repaid toward an outstanding loan.

   The loan balance itself is NOT stored - it's computed live by the
   application by comparing each calendar month's (including the current,
   still-in-progress month) total EmployeeWorkLog.Amount against that
   employee's salary threshold (SalaryAmount for Monthly employees,
   SalaryAmount x days worked that month for Daily employees), then
   subtracting total repayments. Only the repayment side is a real event,
   because it's a genuine cash-in transaction that must also post to
   CashLedger (see EmployeeLoanRepository.CreateRepaymentAsync).

   Idempotent - safe to re-run.
   ===================================================================== */

ALTER TABLE EmployeeMaster ADD COLUMN IF NOT EXISTS SalaryType VARCHAR(10) NOT NULL DEFAULT 'Monthly';
ALTER TABLE EmployeeMaster ADD COLUMN IF NOT EXISTS SalaryAmount DECIMAL(18,2) NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS EmployeeLoanRepayment
(
    EmployeeLoanRepaymentID BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    EmployeeID              INT NOT NULL REFERENCES EmployeeMaster(EmployeeID),
    RepaymentDate           DATE NOT NULL,
    Amount                  DECIMAL(18,2) NOT NULL,
    PaymentMode             VARCHAR(20) NOT NULL,
    Remarks                 VARCHAR(500) NULL,
    CreatedBy               INT NULL,
    CreatedAt               TIMESTAMP NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    UpdatedAt               TIMESTAMP NULL
);

CREATE INDEX IF NOT EXISTS IX_EmployeeLoanRepayment_EmployeeID ON EmployeeLoanRepayment(EmployeeID);
