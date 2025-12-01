import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/api_service.dart';
import '../../utils/notification_helper.dart';

class ViewLogsScreen extends StatefulWidget {
  final User? initialUser;
  final int? initialYear;
  final int? initialMonth;

  const ViewLogsScreen({
    super.key,
    this.initialUser,
    this.initialYear,
    this.initialMonth,
  });

  @override
  State<ViewLogsScreen> createState() => _ViewLogsScreenState();
}

class _ViewLogsScreenState extends State<ViewLogsScreen> {
  User? _selectedUser;
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;
  Log? _logs;
  bool _isLoading = false;
  TimeOfDay _thresholdTime = const TimeOfDay(hour: 8, minute: 0);

  // Analytics Data
  Map<DateTime, List<DateTime>> _logsByDay = {};
  int _onTimeCount = 0;
  int _lateCount = 0;
  int _absentCount = 0;
  String _avgArrival = '--:--';
  String _medianArrival = '--:--';
  String _earliestArrival = '--:--';
  String _latestArrival = '--:--';

  @override
  void initState() {
    super.initState();
    if (widget.initialUser != null) {
      _selectedUser = widget.initialUser;
    }
    if (widget.initialYear != null) {
      _year = widget.initialYear!;
    }
    if (widget.initialMonth != null) {
      _month = widget.initialMonth!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchUserNames();
      if (_selectedUser != null) {
        _fetchLogs();
      }
    });
  }

  Future<void> _fetchLogs() async {
    if (_selectedUser == null) return;

    setState(() => _isLoading = true);
    final token = Provider.of<AdminProvider>(context, listen: false).token;

    if (token != null) {
      try {
        final logs = await ApiService().getLogs(
          _selectedUser!.username,
          _year,
          _month,
          token,
        );
        setState(() {
          _logs = logs;
          _processLogs();
        });
        if (mounted) {
          NotificationHelper.show(
            context,
            isSuccess: true,
            message: 'Logs fetched successfully',
          );
        }
      } catch (e) {
        if (mounted) {
          NotificationHelper.show(
            context,
            isSuccess: false,
            message: e.toString().replaceAll('Exception: ', ''),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _processLogs() {
    if (_logs == null) return;

    _logsByDay = {};
    _onTimeCount = 0;
    _lateCount = 0;
    _absentCount = 0;
    List<Duration> arrivalTimes = [];
    DateTime? minArrival;
    DateTime? maxArrival;

    // Parse logs
    for (var logStr in _logs!.logs) {
      try {
        final dt = DateTime.parse(logStr);
        final day = DateTime(dt.year, dt.month, dt.day);
        if (!_logsByDay.containsKey(day)) {
          _logsByDay[day] = [];
        }
        _logsByDay[day]!.add(dt);
      } catch (e) {
        print('Error parsing log: $logStr');
      }
    }

    // Sort logs per day
    _logsByDay.forEach((day, logs) {
      logs.sort();
    });

    // Calculate Stats
    final daysInMonth = DateUtils.getDaysInMonth(_year, _month);
    final now = DateTime.now();

    for (int i = 1; i <= daysInMonth; i++) {
      final day = DateTime(_year, _month, i);
      if (day.isAfter(now)) continue; // Don't count future days

      if (_logsByDay.containsKey(day) && _logsByDay[day]!.isNotEmpty) {
        final firstLog = _logsByDay[day]!.first;
        final threshold = DateTime(
          day.year,
          day.month,
          day.day,
          _thresholdTime.hour,
          _thresholdTime.minute,
        );

        if (firstLog.isBefore(threshold)) {
          _onTimeCount++;
        } else {
          _lateCount++;
        }

        // Analytics
        final arrival = Duration(
          hours: firstLog.hour,
          minutes: firstLog.minute,
        );
        arrivalTimes.add(arrival);

        if (minArrival == null || firstLog.isBefore(minArrival))
          minArrival = firstLog; // Earliest ever
        // For latest arrival, we usually mean the latest *first* punch, but let's track latest *exit* too?
        // Requirement says "earliest-latest arrival time", implying range of first punches.
        if (maxArrival == null || firstLog.isAfter(maxArrival))
          maxArrival = firstLog;
      } else {
        // Only count absent if it's a weekday? Assuming all days for now.
        // Or maybe exclude weekends? Let's count all past days without logs as absent.
        _absentCount++;
      }
    }

    // Compute Averages/Medians
    if (arrivalTimes.isNotEmpty) {
      // Avg
      int totalMinutes = arrivalTimes.fold(0, (sum, d) => sum + d.inMinutes);
      int avgMinutes = totalMinutes ~/ arrivalTimes.length;
      _avgArrival = _formatMinutes(avgMinutes);

      // Median
      arrivalTimes.sort();
      int mid = arrivalTimes.length ~/ 2;
      int medianMinutes = arrivalTimes[mid].inMinutes;
      if (arrivalTimes.length % 2 == 0) {
        medianMinutes = (medianMinutes + arrivalTimes[mid - 1].inMinutes) ~/ 2;
      }
      _medianArrival = _formatMinutes(medianMinutes);

      // Min/Max
      // We need to show TIME only
      if (minArrival != null)
        _earliestArrival = DateFormat('HH:mm').format(minArrival);
      if (maxArrival != null)
        _latestArrival = DateFormat('HH:mm').format(maxArrival);
    } else {
      _avgArrival = '--:--';
      _medianArrival = '--:--';
      _earliestArrival = '--:--';
      _latestArrival = '--:--';
    }
  }

  String _formatMinutes(int totalMinutes) {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  List<DropdownMenuItem<TimeOfDay>> _buildThresholdItems() {
    List<DropdownMenuItem<TimeOfDay>> items = [];
    for (int h = 0; h < 24; h++) {
      for (int m = 0; m < 60; m += 15) {
        final time = TimeOfDay(hour: h, minute: m);
        items.add(
          DropdownMenuItem(value: time, child: Text(time.format(context))),
        );
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final users = Provider.of<UserProvider>(context).users;

    return Scaffold(
      appBar: AppBar(title: const Text('View Logs')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Controls
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<User>(
                    value: _selectedUser,
                    hint: const Text('User'),
                    items: users
                        .map(
                          (user) => DropdownMenuItem(
                            value: user,
                            child: Text(user.username),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedUser = val),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<int>(
                    value: _year,
                    items: List.generate(5, (i) => DateTime.now().year - i)
                        .map(
                          (y) => DropdownMenuItem(value: y, child: Text('$y')),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _year = val!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<int>(
                    value: _month,
                    items: List.generate(12, (i) => i + 1)
                        .map(
                          (m) => DropdownMenuItem(value: m, child: Text('$m')),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _month = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Late Threshold: '),
                Expanded(
                  child: DropdownButtonFormField<TimeOfDay>(
                    value: _thresholdTime,
                    items: _buildThresholdItems(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _thresholdTime = val;
                          _processLogs(); // Re-process with new threshold
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _selectedUser == null ? null : _fetchLogs,
                  child: const Text('Fetch'),
                ),
              ],
            ),
            const Divider(),

            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_logs != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Analytics Header
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _StatItem('Avg', _avgArrival),
                              _StatItem('Med', _medianArrival),
                              _StatItem('Earliest', _earliestArrival),
                              _StatItem('Latest', _latestArrival),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Summary
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatusChip(
                            'On Time $_onTimeCount',
                            Colors.green,
                            '😊',
                          ),
                          _StatusChip('Late $_lateCount', Colors.orange, '😐'),
                          _StatusChip('Absent $_absentCount', Colors.red, '😞'),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Calendar
                      TableCalendar(
                        firstDay: DateTime(_year, _month, 1),
                        lastDay: DateTime(_year, _month + 1, 0),
                        focusedDay: DateTime(_year, _month, 1),
                        headerVisible: false,
                        calendarFormat: CalendarFormat.month,
                        availableGestures: AvailableGestures.none,
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (context, day, focusedDay) {
                            return _buildCalendarCell(day);
                          },
                          todayBuilder: (context, day, focusedDay) {
                            return _buildCalendarCell(
                              day,
                            ); // Treat today same as others for coloring
                          },
                          outsideBuilder: (context, day, focusedDay) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                      const Divider(),

                      // Log List
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _logs!.logs.length,
                        itemBuilder: (context, index) {
                          // We want to group logs by day in the list?
                          // Or just list them chronologically as requested "Below the calendar, all logs should be there"
                          // "text colour should be as per the category"
                          final logStr = _logs!.logs[index];
                          final dt = DateTime.parse(logStr);
                          final day = DateTime(dt.year, dt.month, dt.day);

                          Color color = Colors.black;
                          String prefix = '';

                          if (_logsByDay.containsKey(day)) {
                            final dayLogs = _logsByDay[day]!;
                            final firstLog = dayLogs.first;
                            final threshold = DateTime(
                              day.year,
                              day.month,
                              day.day,
                              _thresholdTime.hour,
                              _thresholdTime.minute,
                            );

                            if (dt == firstLog) {
                              if (firstLog.isBefore(threshold)) {
                                color = Colors.green;
                                prefix = '😊 (Entry) ';
                              } else {
                                color = Colors.orange;
                                prefix = '😐 (Late) ';
                              }
                            } else if (dayLogs.length > 1 &&
                                dt == dayLogs.last) {
                              color = Colors.blue;
                              prefix = '👋 (Exit) ';
                            }
                          }

                          return ListTile(
                            title: Text(
                              '$prefix$logStr',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              )
            else
              const Expanded(
                child: Center(child: Text('Select User and Fetch Logs')),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarCell(DateTime day) {
    Color? bgColor;
    Color textColor = Colors.black;

    // Normalize day to match map keys (Local Midnight)
    final normalizedDay = DateTime(day.year, day.month, day.day);

    if (_logsByDay.containsKey(normalizedDay) &&
        _logsByDay[normalizedDay]!.isNotEmpty) {
      final firstLog = _logsByDay[normalizedDay]!.first;
      final threshold = DateTime(
        day.year,
        day.month,
        day.day,
        _thresholdTime.hour,
        _thresholdTime.minute,
      );
      if (firstLog.isBefore(threshold)) {
        bgColor = Colors.green;
        textColor = Colors.white;
      } else {
        bgColor = Colors.yellow;
        textColor = Colors.black;
      }
    } else {
      // Absent
      if (normalizedDay.isBefore(DateTime.now())) {
        bgColor = Colors.red;
        textColor = Colors.white;
      }
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Center(
        child: Text('${day.day}', style: TextStyle(color: textColor)),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final String emoji;
  const _StatusChip(this.label, this.color, this.emoji);

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Text(emoji),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }
}
