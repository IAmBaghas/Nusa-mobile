import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/login_response.dart';

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  Future<LoginResponse> login(String username, String password) async {
    try {
      print('Attempting login for user: $username');

      final response = await http.post(
        Uri.parse('$baseUrl/mobile/auth'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      print('Login response status code: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 401) {
        final Map<String, dynamic> data = json.decode(response.body);
        final loginResponse = LoginResponse.fromJson(data);

        // Save token and user data if login was successful
        if (loginResponse.success && loginResponse.token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', loginResponse.token!);
          if (loginResponse.user != null) {
            await prefs.setString('user_data', json.encode(loginResponse.user));
          }
        }

        return loginResponse;
      } else {
        throw Exception('Failed to login. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Login error: $e');
      return LoginResponse.error(e.toString());
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      return json.decode(userDataString);
    }
    return null;
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    if (token == null) return false;

    final requirePasswordChange = await isPasswordChangeRequired();
    return !requirePasswordChange;
  }

  Future<bool> isPasswordChangeRequired() async {
    final userData = await getUserData();
    return userData?['requirePasswordChange'] == true;
  }

  Future<bool> changeFirstTimePassword(String newPassword, int userId) async {
    try {
      final token = await getToken();
      print('Token for password change: $token'); // Debug log

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/mobile/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'newPassword': newPassword,
        }),
      );

      print('Change password response: ${response.statusCode}');
      print('Change password body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Save the new token and user data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('user_data', json.encode(data['user']));

        return true;
      }
      return false;
    } catch (e) {
      print('Change password error: $e');
      rethrow; // Rethrow to handle in UI
    }
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile/search?q=$query'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user_data');
    } catch (e) {
      print('Error during logout: $e');
      throw Exception('Failed to logout');
    }
  }
}
