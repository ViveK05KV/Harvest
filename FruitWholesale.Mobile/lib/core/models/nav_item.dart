import 'package:flutter/material.dart';

import '../../features/settings/company_settings_models.dart';
import 'user_role.dart';

/// A bottom-nav destination, optionally restricted to specific roles —
/// mirrors the `NavItem.roles` pattern in the Angular sidenav.
///
/// [managerUnlockedBy] mirrors `main-layout.component.ts`'s
/// `MANAGER_UNLOCKABLE` table: a handful of Admin-only items (Reports,
/// Profit Calculator) an admin can additionally open to Manager at runtime
/// via a CompanySettings flag, toggled from the Settings screen.
class NavItem {
  final String label;
  final IconData icon;
  final WidgetBuilder builder;
  final List<UserRole>? roles;
  final bool Function(CompanySettings? settings)? managerUnlockedBy;

  const NavItem({
    required this.label,
    required this.icon,
    required this.builder,
    this.roles,
    this.managerUnlockedBy,
  });

  bool visibleTo(UserRole role, CompanySettings? settings) {
    if (roles == null || roles!.contains(role)) return true;
    if (role == UserRole.manager && managerUnlockedBy != null) return managerUnlockedBy!(settings);
    return false;
  }
}

/// A labeled group of [NavItem]s, mirroring the Angular sidenav's `NavGroup`.
class NavGroup {
  final String label;
  final List<NavItem> items;

  const NavGroup({required this.label, required this.items});

  List<NavItem> visibleItems(UserRole role, CompanySettings? settings) =>
      items.where((item) => item.visibleTo(role, settings)).toList();
}
