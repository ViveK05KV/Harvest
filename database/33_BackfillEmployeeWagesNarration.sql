/* =====================================================================
   Fruit Wholesale Management System
   33_BackfillEmployeeWagesNarration.sql

   EmployeeWorkLogRepository used to write generic Cash Ledger narration
   ("Salary (Supply)") for wage payments instead of naming which employee
   got paid. The application code is now fixed for new/edited entries;
   this backfills the narration already stored on existing CashLedger
   rows so the ledger reads correctly without requiring every old entry
   to be manually re-saved.

   Idempotent - safe to re-run.
   ===================================================================== */

UPDATE CashLedger cl
SET Narration = 'Salary - ' || e.FullName || ' (' || w.JobType || ')'
FROM EmployeeWorkLog w
INNER JOIN EmployeeMaster e ON e.EmployeeID = w.EmployeeID
WHERE cl.TransactionType = 'EmployeeWorkLog'
  AND cl.ReferenceTable = 'EmployeeWorkLog'
  AND cl.ReferenceID = w.EmployeeWorkLogID
  AND cl.Narration = 'Salary (' || w.JobType || ')';
