import { Routes } from '@angular/router';
import { authGuard } from './core/guards/auth.guard';
import { roleGuard, homeGuard } from './core/guards/role.guard';

// Staff can access only Supply, Shop Returns, Collections, and Stock (all unguarded below);
// everything else requires Admin/Manager/Accountant.
const backOfficeGuard = [roleGuard('Admin', 'Manager', 'Accountant')];

export const routes: Routes = [
  {
    path: 'login',
    loadComponent: () => import('./auth/login/login.component').then((m) => m.LoginComponent)
  },
  {
    path: '',
    loadComponent: () => import('./layout/main-layout/main-layout.component').then((m) => m.MainLayoutComponent),
    canActivate: [authGuard],
    children: [
      { path: '', pathMatch: 'full', canActivate: [homeGuard], children: [] },
      {
        path: 'dashboard',
        loadComponent: () => import('./features/dashboard/dashboard.component').then((m) => m.DashboardComponent),
        canActivate: backOfficeGuard
      },
      {
        path: 'shops',
        loadComponent: () => import('./features/shop-master/shop-master-list.component').then((m) => m.ShopMasterListComponent),
        canActivate: backOfficeGuard
      },
      {
        path: 'suppliers',
        loadComponent: () =>
          import('./features/supplier-master/supplier-master-list.component').then((m) => m.SupplierMasterListComponent),
        canActivate: backOfficeGuard
      },
      {
        path: 'fruits',
        loadComponent: () => import('./features/fruit-master/fruit-master-list.component').then((m) => m.FruitMasterListComponent),
        canActivate: backOfficeGuard
      },
      {
        path: 'expense-categories',
        loadComponent: () =>
          import('./features/expense-category/expense-category-list.component').then((m) => m.ExpenseCategoryListComponent),
        canActivate: backOfficeGuard
      },
      {
        path: 'routes',
        loadComponent: () => import('./features/route-master/route-master-list.component').then((m) => m.RouteMasterListComponent),
        canActivate: backOfficeGuard
      },
      {
        path: 'employees',
        loadComponent: () => import('./features/employee/employee-list.component').then((m) => m.EmployeeListComponent),
        canActivate: backOfficeGuard
      },
      {
        path: 'stock',
        loadComponent: () => import('./features/stock/stock.component').then((m) => m.StockComponent)
      },
      {
        path: 'supply',
        loadComponent: () => import('./features/supply/supply-list.component').then((m) => m.SupplyListComponent)
      },
      {
        path: 'supply/new',
        loadComponent: () => import('./features/supply/supply-form.component').then((m) => m.SupplyFormComponent)
      },
      {
        path: 'supply/:id/edit',
        loadComponent: () => import('./features/supply/supply-form.component').then((m) => m.SupplyFormComponent)
      },
      {
        path: 'shop-returns',
        loadComponent: () => import('./features/shop-return/shop-return-list.component').then((m) => m.ShopReturnListComponent)
      },
      {
        path: 'shop-returns/new',
        loadComponent: () => import('./features/shop-return/shop-return-form.component').then((m) => m.ShopReturnFormComponent)
      },
      {
        path: 'shop-returns/:id/edit',
        loadComponent: () => import('./features/shop-return/shop-return-form.component').then((m) => m.ShopReturnFormComponent)
      },
      {
        path: 'purchase',
        loadComponent: () => import('./features/purchase/purchase-list.component').then((m) => m.PurchaseListComponent),
        canActivate: backOfficeGuard
      },
      {
        path: 'purchase/new',
        loadComponent: () => import('./features/purchase/purchase-form.component').then((m) => m.PurchaseFormComponent),
        canActivate: backOfficeGuard
      },
      {
        path: 'purchase/:id/edit',
        loadComponent: () => import('./features/purchase/purchase-form.component').then((m) => m.PurchaseFormComponent),
        canActivate: backOfficeGuard
      },
      {
        path: 'collections',
        loadComponent: () => import('./features/collection/collection-list.component').then((m) => m.CollectionListComponent)
      },
      {
        path: 'supplier-returns',
        loadComponent: () =>
          import('./features/supplier-return/supplier-return-list.component').then((m) => m.SupplierReturnListComponent),
        canActivate: backOfficeGuard
      },
      {
        path: 'supplier-returns/new',
        loadComponent: () =>
          import('./features/supplier-return/supplier-return-form.component').then((m) => m.SupplierReturnFormComponent),
        canActivate: backOfficeGuard
      },
      {
        path: 'supplier-returns/:id/edit',
        loadComponent: () =>
          import('./features/supplier-return/supplier-return-form.component').then((m) => m.SupplierReturnFormComponent),
        canActivate: backOfficeGuard
      },
      {
        path: 'supplier-payments',
        loadComponent: () =>
          import('./features/supplier-payment/supplier-payment-list.component').then((m) => m.SupplierPaymentListComponent),
        canActivate: backOfficeGuard
      },
      {
        path: 'daily-expenses',
        loadComponent: () =>
          import('./features/daily-expense/daily-expense-list.component').then((m) => m.DailyExpenseListComponent),
        canActivate: backOfficeGuard
      },
      {
        path: 'employee-salary',
        loadComponent: () =>
          import('./features/employee-work-log/employee-work-log-list.component').then((m) => m.EmployeeWorkLogListComponent),
        canActivate: backOfficeGuard
      },
      {
        path: 'ledgers/shop',
        loadComponent: () => import('./features/ledgers/shop-ledger.component').then((m) => m.ShopLedgerComponent),
        canActivate: backOfficeGuard
      },
      {
        path: 'ledgers/supplier',
        loadComponent: () => import('./features/ledgers/supplier-ledger.component').then((m) => m.SupplierLedgerComponent),
        canActivate: backOfficeGuard
      },
      {
        path: 'ledgers/cash',
        loadComponent: () => import('./features/ledgers/cash-ledger.component').then((m) => m.CashLedgerComponent),
        canActivate: backOfficeGuard
      },
      {
        path: 'reports',
        loadComponent: () => import('./features/reports/reports.component').then((m) => m.ReportsComponent),
        canActivate: [roleGuard('Admin')]
      },
      {
        path: 'profit',
        loadComponent: () => import('./features/profit/profit.component').then((m) => m.ProfitComponent),
        canActivate: [roleGuard('Admin')]
      },
      {
        path: 'users',
        loadComponent: () => import('./features/users/user-list.component').then((m) => m.UserListComponent),
        canActivate: [roleGuard('Admin')]
      },
      {
        path: 'settings',
        loadComponent: () => import('./features/settings/settings.component').then((m) => m.SettingsComponent),
        canActivate: [roleGuard('Admin')]
      }
    ]
  },
  { path: '**', canActivate: [homeGuard], children: [] }
];
