import 'package:intl/intl.dart';

class Agenda {
  final int id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String location;

  Agenda({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.location,
  });

  factory Agenda.fromJson(Map<String, dynamic> json) {
    try {
      // Parse the dates from the mobile-formatted response
      DateTime startDate = DateTime.parse(json['start_date']);
      DateTime endDate = DateTime.parse(json['end_date']);

      return Agenda(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        startDate: startDate,
        endDate: endDate,
        location: json['location'] ?? '',
      );
    } catch (e) {
      print('Error parsing agenda: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  // Helper method to format date for display
  String getFormattedStartDate() {
    return DateFormat('dd MMM yyyy HH:mm').format(startDate);
  }

  String getFormattedEndDate() {
    return DateFormat('dd MMM yyyy HH:mm').format(endDate);
  }

  @override
  String toString() {
    return 'Agenda{id: $id, title: $title, startDate: ${getFormattedStartDate()}, endDate: ${getFormattedEndDate()}, location: $location}';
  }
}
