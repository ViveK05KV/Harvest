/* =====================================================================
   Fruit Wholesale Management System
   04_SeedData.sql
   Seeds only the initial Admin login — no demo company profile, fruits,
   expense categories, or opening cash balance. Add those through the
   app (Settings, Fruit Master, Expense Categories) once you're logged in.

   Default admin login: username "admin" / password "Admin@123"
   BCrypt hash below was generated for "Admin@123" — change it after
   first login.
   ===================================================================== */

INSERT INTO Users (FullName, Username, PasswordHash, Role, IsActive)
SELECT 'System Administrator', 'admin', '$2a$11$Ttdff7b1QzcgO0B7cI0mtuXwZb2dciz5MJHrGeQRwSQ/TduL3j1Wu', 'Admin', TRUE
WHERE NOT EXISTS (SELECT 1 FROM Users WHERE Username = 'admin');
