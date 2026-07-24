import { Component, inject, signal } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { MatSidenavModule } from '@angular/material/sidenav';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatListModule } from '@angular/material/list';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { MatMenuModule } from '@angular/material/menu';
import { MatDividerModule } from '@angular/material/divider';
import { MatTooltipModule } from '@angular/material/tooltip';
import { BreakpointObserver, Breakpoints } from '@angular/cdk/layout';
import { AuthService } from '../../core/services/auth.service';
import { ThemeService } from '../../core/services/theme.service';
import { BrandingService } from '../../core/services/branding.service';
import { UserRole } from '../../core/models/common.model';

interface NavItem {
  label: string;
  icon: string;
  route: string;
  roles?: UserRole[];
}

interface NavGroup {
  label: string;
  items: NavItem[];
}

@Component({
  selector: 'app-main-layout',
  standalone: true,
  imports: [
    RouterOutlet,
    RouterLink,
    RouterLinkActive,
    MatSidenavModule,
    MatToolbarModule,
    MatListModule,
    MatIconModule,
    MatButtonModule,
    MatMenuModule,
    MatDividerModule,
    MatTooltipModule
  ],
  templateUrl: './main-layout.component.html',
  styleUrl: './main-layout.component.scss'
})
export class MainLayoutComponent {
  readonly authService = inject(AuthService);
  readonly themeService = inject(ThemeService);
  readonly branding = inject(BrandingService);
  private readonly breakpointObserver = inject(BreakpointObserver);

  readonly isHandset = signal(false);
  readonly sidenavOpened = signal(true);

  // Staff can access only Supply and Collections; every other item/group requires Admin/Manager/Accountant.
  private static readonly BACK_OFFICE: UserRole[] = ['Admin', 'Manager', 'Accountant'];

  readonly navGroups: NavGroup[] = [
    {
      label: 'Overview',
      items: [{ label: 'Dashboard', icon: 'dashboard', route: '/dashboard', roles: MainLayoutComponent.BACK_OFFICE }]
    },
    {
      label: 'Transactions',
      items: [
        { label: 'Supply', icon: 'local_shipping', route: '/supply' },
        { label: 'Purchase', icon: 'shopping_cart', route: '/purchase', roles: MainLayoutComponent.BACK_OFFICE },
        { label: 'Collections', icon: 'payments', route: '/collections' },
        {
          label: 'Supplier Payments',
          icon: 'account_balance_wallet',
          route: '/supplier-payments',
          roles: MainLayoutComponent.BACK_OFFICE
        },
        { label: 'Daily Expenses', icon: 'receipt_long', route: '/daily-expenses', roles: MainLayoutComponent.BACK_OFFICE },
        { label: 'Employee Salary', icon: 'work_history', route: '/employee-salary', roles: MainLayoutComponent.BACK_OFFICE }
      ]
    },
    {
      label: 'Ledgers',
      items: [
        { label: 'Shop Ledger', icon: 'storefront', route: '/ledgers/shop', roles: MainLayoutComponent.BACK_OFFICE },
        { label: 'Supplier Ledger', icon: 'inventory_2', route: '/ledgers/supplier', roles: MainLayoutComponent.BACK_OFFICE },
        { label: 'Cash Ledger', icon: 'account_balance', route: '/ledgers/cash', roles: MainLayoutComponent.BACK_OFFICE },
        { label: 'Stock', icon: 'inventory', route: '/stock', roles: MainLayoutComponent.BACK_OFFICE }
      ]
    },
    {
      label: 'Reports',
      items: [
        { label: 'Reports', icon: 'assessment', route: '/reports', roles: MainLayoutComponent.BACK_OFFICE },
        { label: 'Profit Calculator', icon: 'trending_up', route: '/profit', roles: ['Admin'] }
      ]
    },
    {
      label: 'Masters',
      items: [
        { label: 'Shops', icon: 'store', route: '/shops', roles: MainLayoutComponent.BACK_OFFICE },
        { label: 'Suppliers', icon: 'groups', route: '/suppliers', roles: MainLayoutComponent.BACK_OFFICE },
        { label: 'Fruits', icon: 'nutrition', route: '/fruits', roles: MainLayoutComponent.BACK_OFFICE },
        { label: 'Routes', icon: 'alt_route', route: '/routes', roles: MainLayoutComponent.BACK_OFFICE },
        { label: 'Employees', icon: 'badge', route: '/employees', roles: MainLayoutComponent.BACK_OFFICE },
        { label: 'Expense Categories', icon: 'category', route: '/expense-categories', roles: MainLayoutComponent.BACK_OFFICE }
      ]
    },
    {
      label: 'Administration',
      items: [
        { label: 'Users', icon: 'manage_accounts', route: '/users', roles: ['Admin'] },
        { label: 'Settings', icon: 'settings', route: '/settings', roles: ['Admin', 'Accountant'] }
      ]
    }
  ];

  constructor() {
    this.breakpointObserver.observe(Breakpoints.Handset).subscribe((result) => {
      this.isHandset.set(result.matches);
      this.sidenavOpened.set(!result.matches);
    });
    this.branding.refresh();
  }

  visibleGroups(): NavGroup[] {
    return this.navGroups
      .map((group) => ({
        label: group.label,
        items: group.items.filter((item) => !item.roles || this.authService.hasRole(...item.roles))
      }))
      .filter((group) => group.items.length > 0);
  }

  toggleSidenav(): void {
    this.sidenavOpened.update((v) => !v);
  }

  logout(): void {
    this.authService.logout();
  }
}
