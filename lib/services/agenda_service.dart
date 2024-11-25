import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:async';
import '../models/agenda.dart';
import '../services/event_bus_service.dart';

class AgendaService {
  static final AgendaService _instance = AgendaService._internal();
  factory AgendaService() => _instance;
  AgendaService._internal();

  final String baseUrl = Platform.isAndroid
      ? 'http://10.0.2.2:5000/api'
      : 'http://localhost:5000/api';

  final _eventBus = EventBusService();
  Timer? _refreshTimer;

  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      refreshAgendas();
    });
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> refreshAgendas() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mobile/agenda/upcoming'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> data = jsonResponse['data'];
          final agendas = data.map((json) => Agenda.fromJson(json)).toList();

          // Emit update event
          _eventBus.emitAgendaUpdate(AgendaUpdateEvent(
            agendas: agendas,
          ));
        }
      }
    } catch (e) {
      print('Error refreshing agendas: $e');
    }
  }

  void initialize() {
    startAutoRefresh();
    refreshAgendas(); // Initial refresh
  }

  void dispose() {
    stopAutoRefresh();
  }
}
