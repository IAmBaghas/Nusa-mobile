import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'change_password_screen.dart';

class AuthCheck extends StatelessWidget {
  final _authService = AuthService();

  AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _authService.getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final userData = snapshot.data;

        // No user data means not logged in
        if (userData == null) {
          return const LoginScreen();
        }

        // Check if password change is required
        if (userData['requirePasswordChange'] == true) {
          return ChangePasswordScreen(userId: userData['id']);
        }

        // User is logged in and no password change required
        return const MainScreen();
      },
    );
  }
}
