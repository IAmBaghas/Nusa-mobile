import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article.dart';
import '../models/agenda.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator to access localhost
  // For real devices, use your computer's IP address
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  Future<List<Article>> fetchArticles() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts/latest'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Article.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load articles: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching articles: $e');
    }
  }

  Future<List<Agenda>> fetchAgendas() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/agenda'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Agenda.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load agendas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching agendas: $e');
    }
  }

  Future<List<Article>> fetchAllArticles() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Article.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load articles: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching articles: $e');
    }
  }
}
