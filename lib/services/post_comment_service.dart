import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../models/post_comment.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostCommentService {
  final String baseUrl = Platform.isAndroid
      ? 'http://10.0.2.2:5000/api'
      : 'http://localhost:5000/api';

  Future<List<PostComment>> getComments(int postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/siswa-posts/$postId/comments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> data = responseData['data'];
          return data.map((json) => PostComment.fromJson(json)).toList();
        } else {
          throw Exception('Failed to parse comments data');
        }
      } else {
        throw Exception('Failed to load comments');
      }
    } catch (e) {
      throw Exception('Error getting comments: $e');
    }
  }

  Future<bool> deleteComment(int postId, int commentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No token found');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/siswa-posts/$postId/comments/$commentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData['success'] == true;
      } else {
        throw Exception('Failed to delete comment');
      }
    } catch (e) {
      throw Exception('Error deleting comment: $e');
    }
  }

  Future<(PostComment?, int)> getLatestComment(int postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/siswa-posts/$postId/comments/latest'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          final comment = data['comment'] != null
              ? PostComment.fromJson(data['comment'])
              : null;
          final totalComments = data['totalComments'] as int;
          return (comment, totalComments);
        }
      }
      return (null, 0);
    } catch (e) {
      print('Error getting latest comment: $e');
      return (null, 0);
    }
  }

  Future<(PostComment, int)> createComment(int postId, String content) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No token found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/siswa-posts/$postId/comments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'content': content}),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final commentData = responseData['data'];
          final comment = PostComment.fromJson(commentData);
          final commentCount = await getCommentCount(postId);
          return (comment, commentCount);
        } else {
          throw Exception('Failed to parse comment data');
        }
      } else {
        throw Exception('Failed to create comment');
      }
    } catch (e) {
      throw Exception('Error creating comment: $e');
    }
  }

  Future<int> getCommentCount(int postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/siswa-posts/$postId/comments/count'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['count'];
        }
        throw Exception('Failed to get comment count');
      } else {
        throw Exception('Failed to get comment count: ${response.body}');
      }
    } catch (e) {
      print('Error getting comment count: $e');
      throw e;
    }
  }
}
