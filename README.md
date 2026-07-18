# Fruit Wholesale Management System

A production-ready ERP for a fruit wholesale business: supply/purchase invoicing, customer collections, supplier payments, daily expenses, and fully automatic double-entry-style ledgers (Shop, Supplier, Cash), built on Clean Architecture with ASP.NET Core and Angular.

## Technology Stack

| Layer | Technology |
|---|---|
| Backend API | ASP.NET Core **10** Web API (see note below), C# |
| Data access | Dapper + Microsoft.Data.SqlClient (no ORM) |
| Database | SQL Server |
| Auth | JWT Bearer |
| Validation | FluentValidation (via a global MVC action filter) |
| Mapping | AutoMapper |
| Logging | Serilog (console + rolling file sink) |
| API docs | Swagger / Swashbuckle |
| Frontend | Angular 20 (standalone components, signals, new control-flow syntax) |
| UI kit | Angular Material 3 only — minimalist M3 design, no Bootstrap dependency |
| Charts | Chart.js (via a small wrapper component) |
| Export | SheetJS (xlsx) + jsPDF/autoTable |

> **Note on version:** the spec calls for ASP.NET Core 9, but this machine only has the **.NET 10 SDK** installed (no .NET 9 runtime). The solution targets **net10.0** so it actually runs here. To retarget to net9.0, install the .NET 9 SDK and change `<TargetFramework>` in each `.csproj`, plus `FruitWholesale.Client`'s Angular version is unaffected.

## Solution Structure

```
FruitWholesale.slnx
src/
  FruitWholesale.Domain/          Entities, domain enums/constants — no dependencies
  FruitWholesale.Shared/          Result<T> pattern, PaginatedList<T>, shared exceptions
  FruitWholesale.Application/     DTOs, service interfaces + implementations, FluentValidation
                                   validators, AutoMapper profile, repository interfaces
  FruitWholesale.Infrastructure/  Dapper repository implementations, LedgerService (the
                                   ledger-synchronization engine), JWT token issuing
  FruitWholesale.Api/             Controllers, Program.cs (DI/auth/Swagger/Serilog wiring),
                                   global exception handler, validation filter
FruitWholesale.Client/            Angular 20 SPA
  src/app/core/                   models, services (auth/theme/notification/export),
                                   interceptors, guards
  src/app/layout/                 collapsible sidenav + toolbar shell
  src/app/auth/                   login
  src/app/shared/                 confirm-dialog, Chart.js wrapper
  src/app/features/               one folder per module (dashboard, shop-master,
                                   supplier-master, fruit-master, expense-category,
                                   route-master, employee, employee-work-log, stock,
                                   supply, purchase, collection, supplier-payment,
                                   daily-expense, ledgers, reports, users, settings)
database/
  01_CreateDatabase_Tables.sql    Idempotent — drops/recreates everything in dependency order
  02_Indexes.sql                  Idempotent (DROP INDEX IF EXISTS then CREATE)
  03_StoredProcedures.sql         Ledger recalculation procs (incl. stock) + dashboard summary proc
  04_SeedData.sql                 Admin login only
  05_ClearData.sql                Standalone reset — wipes all data except the admin login
```

Dependency direction is strictly inward: `Api → Infrastructure → Application → Domain/Shared`. `Application` only references abstractions (`IDbConnectionFactory`, repository interfaces); `Infrastructure` provides the Dapper-backed implementations.

## Ledger Synchronization Design

This is the core business rule of the whole system, so it's worth explaining how it's implemented:

- **`ILedgerService`** (`Application/Common/Interfaces`, implemented in `Infrastructure/Services/LedgerService.cs`) is the only code path allowed to write to `ShopLedger`, `SupplierLedger`, and `CashLedger`.
- Every transactional repository (`SupplyRepository`, `PurchaseRepository`, `CollectionRepository`, `SupplierPaymentRepository`, `DailyExpenseRepository`, and the master-data repositories for opening balances) opens **one SQL transaction**, writes its own table(s), calls `ILedgerService` to add/remove the matching ledger row(s) inside that same transaction, then calls the matching `sp_Recalculate*Balance` stored procedure before committing.
- Recalculation (not just appending a running total) is what makes backdated entries, edits, and deletes correct — the stored procs re-derive `RunningBalance` for every row of the affected shop/supplier (or the whole cash ledger) in one set-based pass, in `(TransactionDate, LedgerID)` order.
- Opening balances (`ShopMaster.OpeningBalance`, `SupplierMaster.OpeningBalance`, `CompanySettings.OpeningCashBalance`) are booked as their own `OpeningBalance`-type ledger row at creation time — never added a second time by the recalculation procs (an earlier bug during development double-counted this; see the stored procedures for the fix and comment explaining why they sum from zero).
- The only way to touch `CashLedger` outside of an automatic transaction is `POST /api/companysettings/cash-adjustment` (Admin/Accountant only), which books an explicit `Adjustment` row — this matches the business rule "CashLedger must never be edited manually except Opening Balance and Cash Adjustment."
- The same pattern extends to stock: `StockLedger` tracks fruit quantity, with `sp_RecalculateStockLedgerBalance` recomputing `RunningStock` the same way. Every Purchase item books `QuantityIn`, every Supply item books `QuantityOut`, both inside the existing Purchase/Supply transaction — so stock, the supplier/shop ledger, and the source document always commit or roll back together. `POST /api/stock/adjustment` (Admin/Manager only) is the manual-correction escape hatch, mirroring Cash Adjustment.

## Routes, Employees & Stock

- **RouteMaster** groups shops into delivery routes — a wholesaler can run more than one. `ShopMaster.RouteID` is a nullable FK; assign a shop to a route from the Shop form or leave it unassigned.
- **EmployeeMaster** is deliberately a plain staff directory (name, phone, address) — employees have no fixed route or fixed working days, since in practice who goes where changes day to day.
- **EmployeeWorkLog** (`/employee-salary` in the app) is where that variability is actually recorded: one row per day an employee did paid work, with a `JobType` (`Supply`, `Collection`, `Loading`, `Other`), an optional `RouteID` (only relevant for Supply/Collection — the form hides the route picker for Loading/Other), an `Amount`, and a `PaymentMode`. Every entry with `Amount > 0` books a `CashLedger` "Cash Out" entry inside the same transaction, exactly like `DailyExpense` — edits and deletes reverse and re-book automatically.
- **Stock** (`/stock` in the app) shows current on-hand quantity per fruit, computed from the latest `StockLedger` row per `FruitID`, with a drill-down ledger view and a manual adjustment dialog.

## Getting Started

### 1. Database

Requires a local or reachable SQL Server instance (Windows Authentication by default).

```bash
cd database
sqlcmd -S localhost -E -i 01_CreateDatabase_Tables.sql
sqlcmd -S localhost -E -i 02_Indexes.sql
sqlcmd -S localhost -E -i 03_StoredProcedures.sql
sqlcmd -S localhost -E -i 04_SeedData.sql
```

All scripts are idempotent — re-running them drops and recreates cleanly. `04_SeedData.sql` seeds **only the admin login** — no demo company profile, fruits, or expense categories; add those yourself once you're logged in. `05_ClearData.sql` is a standalone reset: run it any time to wipe every table back to empty except the admin user, without dropping/recreating the schema.

Update `src/FruitWholesale.Api/appsettings.json` → `ConnectionStrings:DefaultConnection` if your SQL Server isn't `localhost` with Windows auth.

### 2. Backend API

```bash
dotnet build FruitWholesale.slnx
dotnet run --project src/FruitWholesale.Api/FruitWholesale.Api.csproj --urls http://localhost:5080
```

Swagger UI: http://localhost:5080/swagger

**Default login:** `admin` / `Admin@123` (change it from Settings → Change Password after first login).

> The JWT signing secret in `appsettings.json` is a real random value generated for this environment — rotate it before any real deployment, and never commit production secrets.

### 3. Frontend

```bash
cd FruitWholesale.Client
npm install
npm run start
```

App: http://localhost:4200 — configured (`src/environments/environment.ts`) to call the API at `http://localhost:5080/api`.

## Modules

Dashboard · Users (Admin) · Shop Management · Supplier Management · Fruit Master · Routes · Employees · Employee Salary · Stock · Supply · Purchase · Collections · Supplier Payments · Expense Category · Daily Expenses · Shop Ledger · Supplier Ledger · Cash Ledger · Reports (Daily Sales, Daily Collection, Daily Expense, Purchase, Fruit Sales, Outstanding, Profit Summary) · Settings (Company Profile, Change Password, Cash Adjustment) · Authentication

## Roles

`Admin`, `Manager`, `Accountant`, `Staff`. Only `Admin` can manage Users; Cash Adjustment is restricted to `Admin`/`Accountant`. All other endpoints require authentication but not a specific role — tighten `[Authorize(Roles = ...)]` on `Api/Controllers/*` as your operational policy requires.

## Known Limitations / Follow-ups

- No automated test project yet (unit/integration tests for `LedgerService` and the repositories would be the highest-value addition given how much correctness depends on that code path).
- `Serilog.Sinks.MSSqlServer` is referenced but not wired into `Program.cs`'s logger config (console + rolling file only) — add a `WriteTo.MSSqlServer(...)` sink pointed at a logging table if centralized DB logging is wanted.
- Angular route guards check role client-side for UI purposes only; the API's `[Authorize(Roles=...)]` attributes are the actual enforcement boundary.
