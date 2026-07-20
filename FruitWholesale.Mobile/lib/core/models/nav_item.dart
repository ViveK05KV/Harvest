import 'package:flutter/material.dart';

import 'user_role.dart';

/// A bottom-nav destination, optionally restricted to specific roles —
/// mirrors the `NavItem.roles` pattern in the Angular sidenav.
class NavItem {
  final String label;
  final IconData icon;
  final WidgetBuilder builder;
  final List<UserRole>? roles;

  const NavItem({
    required this.label,
    required this.icon,
    required this.builder,
    this.roles,
  });

  bool visibleTo(UserRole role) => roles == null || roles!.contains(role);
}

/// A labeled group of [NavItem]s, mirroring the Angular sidenav's `NavGroup`.
class NavGroup {
  final String label;
  final List<NavItem> items;

  const NavGroup({required this.label, required this.items});

  List<NavItem> visibleItems(UserRole role) => items.where((item) => item.visibleTo(role)).toList();
}
