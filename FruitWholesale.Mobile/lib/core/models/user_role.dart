/// Mirrors `Domain.Enums.UserRoles` on the backend and the access matrix
/// enforced in the Angular client's role guards / nav groups.
enum UserRole {
  admin,
  manager,
  accountant,
  staff;

  static UserRole fromApi(String value) {
    switch (value) {
      case 'Admin':
        return UserRole.admin;
      case 'Manager':
        return UserRole.manager;
      case 'Accountant':
        return UserRole.accountant;
      case 'Staff':
        return UserRole.staff;
      default:
        throw ArgumentError('Unknown role: $value');
    }
  }

  /// True for Admin/Manager/Accountant — the roles with full back-office access.
  bool get isBackOffice => this != UserRole.staff;

  /// The exact string the backend uses (round-trips through [fromApi]).
  String get toApi {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.manager:
        return 'Manager';
      case UserRole.accountant:
        return 'Accountant';
      case UserRole.staff:
        return 'Staff';
    }
  }
}
