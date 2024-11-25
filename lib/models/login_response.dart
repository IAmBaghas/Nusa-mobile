class LoginResponse {
  final bool success;
  final String? message;
  final bool requirePasswordChange;
  final int userId;
  final bool isActive;
  final String? token;
  final Map<String, dynamic>? user;

  LoginResponse({
    required this.success,
    this.message,
    required this.requirePasswordChange,
    required this.userId,
    required this.isActive,
    this.token,
    this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      requirePasswordChange: json['require_password_change'] as bool? ?? false,
      userId: json['user_id'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      token: json['token'] as String?,
      user: json['user'] as Map<String, dynamic>?,
    );
  }

  factory LoginResponse.error(String message) {
    return LoginResponse(
      success: false,
      message: message,
      requirePasswordChange: false,
      userId: 0,
      isActive: true,
      token: null,
      user: null,
    );
  }

  @override
  String toString() {
    return 'LoginResponse{success: $success, message: $message, requirePasswordChange: $requirePasswordChange, userId: $userId, isActive: $isActive, hasToken: ${token != null}, hasUser: ${user != null}}';
  }
}
