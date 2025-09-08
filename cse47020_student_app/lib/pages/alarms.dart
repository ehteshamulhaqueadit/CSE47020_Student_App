import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:cse47020_student_app/api/bracu_auth_manager.dart';
import 'package:cse47020_student_app/model/section_info.dart';

class AlarmPage extends StatefulWidget {
  const AlarmPage({super.key});

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  late Future<List<Section>> _futureSections;
  final Map<String, int> _minutesBefore = {};

  @override
  void initState() {
    super.initState();
    _futureSections = _fetchSchedule();
  }

  Future<List<Section>> _fetchSchedule() async {
    final jsonString = await BracuAuthManager().getStudentSchedule();
    if (jsonString == null) {
      throw Exception("No schedule data available");
    }

    final decoded = jsonDecode(jsonString) as List<dynamic>;
    return decoded.map((e) => Section.fromJson(e)).toList();
  }

  Future<void> _setAlarm(
    List<String> days,
    String startTime,
    String courseCode,
    int minutesBefore,
  ) async {
    final timeParts = startTime.split(':');
    var hour = int.parse(timeParts[0]);
    var minute = int.parse(timeParts[1]);

    final classTime = DateTime(2025, 1, 1, hour, minute); // dummy date
    final adjusted = classTime.subtract(Duration(minutes: minutesBefore));
    hour = adjusted.hour;
    minute = adjusted.minute;

    final dayMapping = {
      'SUNDAY': 1,
      'MONDAY': 2,
      'TUESDAY': 3,
      'WEDNESDAY': 4,
      'THURSDAY': 5,
      'FRIDAY': 6,
      'SATURDAY': 7,
    };

    final alarmDays =
        days.map((day) => dayMapping[day]).whereType<int>().toList();

    final intent = AndroidIntent(
      action: 'android.intent.action.SET_ALARM',
      arguments: {
        'android.intent.extra.alarm.HOUR': hour,
        'android.intent.extra.alarm.MINUTES': minute,
        'android.intent.extra.alarm.MESSAGE':
            '$courseCode Class Reminder ($minutesBefore min before)',
        'android.intent.extra.alarm.DAYS': alarmDays,
        'android.intent.extra.alarm.SKIP_UI': false,
      },
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );

    await intent.launch();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: FutureBuilder<List<Section>>(
        future: _futureSections,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final sections = snapshot.data ?? [];

          return ListView.builder(
            itemCount: sections.length,
            itemBuilder: (context, index) {
              final section = sections[index];
              final schedules = section.sectionSchedule.classSchedules;
              if (schedules.isEmpty) return const SizedBox.shrink();

              final courseCode = section.courseCode;
              _minutesBefore.putIfAbsent(courseCode, () => 10);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                // elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        courseCode,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        schedules
                            .map((s) =>
                                "${s.day} ${s.startTime}-${s.endTime}")
                            .join("\n"),
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),

                      // Row with increment/decrement
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                if (_minutesBefore[courseCode]! > 5) {
                                  _minutesBefore[courseCode] =
                                      _minutesBefore[courseCode]! - 5;
                                }
                              });
                            },
                            child: const Icon(Icons.remove),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              "${_minutesBefore[courseCode]} min before",
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _minutesBefore[courseCode] =
                                    _minutesBefore[courseCode]! + 5;
                              });
                            },
                            child: const Icon(Icons.add),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Centered Set Alarm button
                      Center(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          onPressed: () async {
                            final days = schedules.map((s) => s.day).toList();
                            final startTime = schedules.isNotEmpty
                                ? schedules.first.startTime
                                : "";

                            if (startTime.isNotEmpty && days.isNotEmpty) {
                              await _setAlarm(
                                days,
                                startTime,
                                courseCode,
                                _minutesBefore[courseCode]!,
                              );
                            }
                          },
                          icon: const Icon(Icons.check),
                          label: const Text("Set Alarm"),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

