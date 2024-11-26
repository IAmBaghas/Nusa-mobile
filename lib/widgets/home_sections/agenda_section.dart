import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'dart:io';
import '../../models/agenda.dart';
import '../../services/event_bus_service.dart';
import '../../services/agenda_service.dart';
import 'dart:async';

class AgendaSection extends StatefulWidget {
  const AgendaSection({super.key});

  @override
  State<AgendaSection> createState() => AgendaSectionState();
}

class AgendaSectionState extends State<AgendaSection> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isCalendarExpanded = false;
  List<Agenda> _agendas = [];
  bool _isLoading = true;
  StreamSubscription? _agendaUpdateSubscription;

  @override
  void initState() {
    super.initState();
    AgendaService().initialize();
    _loadAgendas();

    // Listen for agenda updates
    _agendaUpdateSubscription = EventBusService().agendaUpdates.listen((event) {
      if (mounted) {
        setState(() {
          _agendas = event.agendas;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    AgendaService().dispose();
    _agendaUpdateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadAgendas() async {
    setState(() => _isLoading = true);
    try {
      await AgendaService().refreshAgendas();
    } catch (e) {
      print('Error loading agendas: $e');
      if (mounted) {
        setState(() {
          _agendas = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> loadData() async {
    await _loadAgendas();
  }

  List<Agenda> get _upcomingAgendas {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _agendas.where((agenda) {
      final agendaDate = DateTime(
        agenda.startDate.year,
        agenda.startDate.month,
        agenda.startDate.day,
      );
      return agendaDate.compareTo(today) >= 0;
    }).toList();
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return months[month - 1];
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();
    return '${localDate.day} ${_getMonthName(localDate.month)} ${localDate.year}';
  }

  String _formatTime(DateTime date) {
    final localDate = date.toLocal();
    return '${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')} WIB';
  }

  Widget _buildTimeRow(BuildContext context, String label, String date,
      String time, bool isPast) {
    return DefaultTextStyle(
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: isPast
                ? Theme.of(context).colorScheme.outline
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
      child: Row(
        children: [
          if (label.isNotEmpty) ...[
            Text(label),
            const SizedBox(width: 8),
          ],
          if (date.isNotEmpty) ...[
            Text(date),
            const SizedBox(width: 8),
          ],
          Text(time),
        ],
      ),
    );
  }

  void _showAgendaDetails(BuildContext context, Agenda agenda) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                agenda.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow(context, 'Mulai',
                  '${_formatDate(agenda.startDate)} ${_formatTime(agenda.startDate)}'),
              const SizedBox(height: 8),
              _buildDetailRow(context, 'Selesai',
                  '${_formatDate(agenda.endDate)} ${_formatTime(agenda.endDate)}'),
              const SizedBox(height: 16),
              const SizedBox(height: 8),
              Text(agenda.description),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDayAgendas(
      BuildContext context, List<Agenda> agendas, DateTime date) {
    final sortedAgendas = agendas
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final bool hasMultipleAgendas = agendas.length > 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: hasMultipleAgendas,
      builder: (context) {
        if (hasMultipleAgendas) {
          return DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.3,
            maxChildSize: 0.8,
            expand: false,
            builder: (context, scrollController) {
              return _buildAgendaList(
                  context, sortedAgendas, date, scrollController);
            },
          );
        } else {
          return _buildAgendaList(context, sortedAgendas, date, null);
        }
      },
    );
  }

  Widget _buildAgendaList(BuildContext context, List<Agenda> sortedAgendas,
      DateTime date, ScrollController? scrollController) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Agenda - ${_formatDate(date)}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          if (sortedAgendas.length > 1)
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                itemCount: sortedAgendas.length,
                separatorBuilder: (context, index) => Divider(
                  height: 32,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                itemBuilder: (context, index) =>
                    _buildAgendaItem(context, sortedAgendas[index]),
              ),
            )
          else
            _buildAgendaItem(context, sortedAgendas[0]),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgendaItem(BuildContext context, Agenda agenda) {
    final isPast = agenda.endDate.isBefore(DateTime.now());
    final isMultiDay = !isSameDay(agenda.startDate, agenda.endDate);

    return InkWell(
      onTap: () => _showAgendaDetails(context, agenda),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              agenda.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isPast
                        ? Theme.of(context).colorScheme.outline
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            if (isMultiDay) ...[
              _buildTimeRow(context, 'Mulai:', _formatDate(agenda.startDate),
                  _formatTime(agenda.startDate), isPast),
              const SizedBox(height: 4),
              _buildTimeRow(context, 'Selesai:', _formatDate(agenda.endDate),
                  _formatTime(agenda.endDate), isPast),
            ] else
              _buildTimeRow(
                  context,
                  '',
                  '',
                  '${_formatTime(agenda.startDate)} - ${_formatTime(agenda.endDate)}',
                  isPast),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Agenda Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Agenda Mendatang',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              FilledButton.tonalIcon(
                icon: Icon(
                  _isCalendarExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.calendar_month,
                  size: 20,
                ),
                label: Text(
                  _isCalendarExpanded ? 'Tutup Kalender' : 'Buka Kalender',
                  style: const TextStyle(fontSize: 14),
                ),
                onPressed: () {
                  setState(() {
                    _isCalendarExpanded = !_isCalendarExpanded;
                  });
                },
              ),
            ],
          ),
        ),

        // Expandable Calendar
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: _isCalendarExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2024, 1, 1),
              lastDay: DateTime.utc(2024, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;

                  final eventsOnDay = _agendas.where((agenda) {
                    final startDate = DateTime(
                      agenda.startDate.year,
                      agenda.startDate.month,
                      agenda.startDate.day,
                    );
                    final endDate = DateTime(
                      agenda.endDate.year,
                      agenda.endDate.month,
                      agenda.endDate.day,
                    );
                    final currentDate = DateTime(
                      selectedDay.year,
                      selectedDay.month,
                      selectedDay.day,
                    );

                    return !currentDate.isBefore(startDate) &&
                        !currentDate.isAfter(endDate);
                  }).toList();

                  if (eventsOnDay.isNotEmpty) {
                    _showDayAgendas(context, eventsOnDay, selectedDay);
                  }
                });
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
                selectedTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle:
                    Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: Theme.of(context).colorScheme.primary,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  final List<Agenda> dayEvents = _agendas.where((agenda) {
                    final startDate = DateTime(
                      agenda.startDate.year,
                      agenda.startDate.month,
                      agenda.startDate.day,
                    );
                    final endDate = DateTime(
                      agenda.endDate.year,
                      agenda.endDate.month,
                      agenda.endDate.day,
                    );
                    final currentDate = DateTime(
                      date.year,
                      date.month,
                      date.day,
                    );

                    return !currentDate.isBefore(startDate) &&
                        !currentDate.isAfter(endDate);
                  }).toList();

                  if (dayEvents.isEmpty) return null;

                  final bool allPastEvents = dayEvents.every(
                    (event) => event.endDate.isBefore(DateTime.now()),
                  );

                  bool isStart =
                      dayEvents.any((e) => isSameDay(e.startDate, date));
                  bool isEnd = dayEvents.any((e) => isSameDay(e.endDate, date));

                  return Stack(
                    children: [
                      // Center line that spans the full width
                      Positioned(
                        bottom: 2,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 4,
                          color: allPastEvents
                              ? Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withOpacity(0.3)
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      // Rounded caps for start and end dates
                      if (isStart)
                        Positioned(
                          bottom: 2,
                          left: 0,
                          child: Container(
                            width: 16,
                            height: 4,
                            decoration: BoxDecoration(
                              color: allPastEvents
                                  ? Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withOpacity(0.3)
                                  : Theme.of(context).colorScheme.primary,
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      if (isEnd)
                        Positioned(
                          bottom: 2,
                          right: 0,
                          child: Container(
                            width: 16,
                            height: 4,
                            decoration: BoxDecoration(
                              color: allPastEvents
                                  ? Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withOpacity(0.3)
                                  : Theme.of(context).colorScheme.primary,
                              borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(2),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          secondChild: const SizedBox(height: 8),
        ),

        // Agenda Cards
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _upcomingAgendas.length,
              itemBuilder: (context, index) {
                final agenda = _upcomingAgendas[index];
                return GestureDetector(
                  onTap: () => _showAgendaDetails(context, agenda),
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          agenda.startDate.day.toString(),
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          _getMonthName(agenda.startDate.month),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer,
                                  ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
