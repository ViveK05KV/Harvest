import 'user_role.dart';

/// Mirrors the backend's `LoginResponseDto`.
class CurrentUser {
  final String token;
  final DateTime expiresAt;
  final String refreshToken;
  final int userId;
  final String fullName;
  final String username;
  final UserRole role;

  const CurrentUser({
    required this.token,
    required this.expiresAt,
    required this.refreshToken,
    required this.userId,
    required this.fullName,
    required this.username,
    required this.role,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    return CurrentUser(
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      refreshToken: json['refreshToken'] as String,
      userId: json['userID'] as int,
      fullName: json['fullName'] as String,
      username: json['username'] as String,
      role: UserRole.fromApi(json['role'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'token': token,
        'expiresAt': expiresAt.toIso8601String(),
        'refreshToken': refreshToken,
        'userID': userId,
        'fullName': fullName,
        'username': username,
        'role': role.toApi,
      };
}
