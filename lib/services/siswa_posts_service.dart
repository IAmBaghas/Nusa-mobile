import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/siswa_post.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class SiswaPostsService {
  final String baseUrl = Platform.isAndroid
      ? 'http://10.0.2.2:5000/api'
      : 'http://localhost:5000/api';

  // Get token from SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Get user data from SharedPreferences
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      return json.decode(userDataString);
    }
    return null;
  }

  // Get all posts
  Future<List<SiswaPost>> getAllPosts() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/siswa-posts'),
        headers: {
          'Authorization': token != null ? 'Bearer $token' : '',
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> postsJson = jsonResponse['data'];
          return postsJson.map((json) => SiswaPost.fromJson(json)).toList();
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to load posts');
        }
      } else if (response.statusCode == 404) {
        return []; // Return empty list if no posts found
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getAllPosts: $e');
      throw Exception('Failed to load posts: $e');
    }
  }

  // Get posts by profile
  Future<List<SiswaPost>> getPostsByProfile(int profileId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/siswa-posts/profile/$profileId'),
        headers: {
          'Authorization': token != null ? 'Bearer $token' : '',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> postsJson = jsonResponse['data'];
          return postsJson.map((json) => SiswaPost.fromJson(json)).toList();
        } else if (response.statusCode == 404) {
          return []; // Return empty list if no posts found
        } else {
          throw Exception(
              jsonResponse['message'] ?? 'Failed to load profile posts');
        }
      } else {
        throw Exception('Failed to load profile posts');
      }
    } catch (e) {
      print('Error in getPostsByProfile: $e');
      throw Exception('Failed to load profile posts: $e');
    }
  }

  // Create new post
  Future<bool> createPost(String caption, List<File> images) async {
    try {
      final authService = AuthService();
      final token = await authService.getToken();
      if (token == null) throw Exception('Not authenticated');

      final url = Uri.parse('$baseUrl/siswa-posts');
      var request = http.MultipartRequest('POST', url);

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Content-Type'] = 'multipart/form-data';

      // Add caption as form field with explicit encoding
      print('Adding caption to request: "$caption"'); // Debug log
      request.fields.addAll({
        'caption': caption,
      });

      // Add images
      for (var image in images) {
        print('Adding image: ${image.path}'); // Debug log
        final file = await http.MultipartFile.fromPath(
          'images',
          image.path,
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(file);
      }

      // Print the entire request for debugging
      print('Request fields: ${request.fields}');
      print('Request files: ${request.files.length}');

      // Send request and get response
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Create post response status: ${response.statusCode}');
      print('Create post response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Unknown error occurred');
      }
    } catch (e) {
      print('Error creating post: $e');
      rethrow;
    }
  }

  // Delete post
  Future<void> deletePost(int postId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse('$baseUrl/siswa-posts/$postId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete post: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  // Check if post is liked
  Future<bool> checkLike(int postId) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final response = await http.get(
        Uri.parse('$baseUrl/siswa-posts/$postId/like'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['liked'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking like: $e');
      return false;
    }
  }

  // Toggle like on post
  Future<bool> toggleLike(int postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('$baseUrl/siswa-posts/$postId/like'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['liked'];
      } else {
        throw Exception('Failed to toggle like');
      }
    } catch (e) {
      throw Exception('Error toggling like: $e');
    }
  }

  // Get like count
  Future<int> getLikeCount(int postId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/siswa-posts/$postId/like-count'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['count'];
      } else {
        throw Exception('Failed to get like count');
      }
    } catch (e) {
      throw Exception('Error getting like count: $e');
    }
  }

  // Add this method to fetch main page posts
  Future<List<SiswaPost>> getMainPagePosts() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/siswa-posts/main-page'),
        headers: {
          'Authorization': token != null ? 'Bearer $token' : '',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> postsJson = jsonResponse['data'];
          return postsJson.map((json) => SiswaPost.fromJson(json)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception(
            'Failed to load main page posts: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getMainPagePosts: $e');
      throw Exception('Failed to load main page posts: $e');
    }
  }
}
