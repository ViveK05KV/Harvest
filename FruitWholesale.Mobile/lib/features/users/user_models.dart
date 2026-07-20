/// Matches USER_ROLES in the backend/Angular models.
const List<String> userRoleOptions = ['Admin', 'Manager', 'Accountant', 'Staff'];

class AppUser {
  final int userId;
  final String fullName;
  final String username;
  final String role;
  final bool isActive;
  final DateTime createdAt;

  const AppUser({
    this.userId = 0,
    required this.fullName,
    required this.username,
    required this.role,
    this.isActive = true,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      userId: json['userID'] as int,
      fullName: json['fullName'] as String,
      username: json['username'] as String,
      role: json['role'] as String,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
