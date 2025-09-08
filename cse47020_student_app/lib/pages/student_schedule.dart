import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cse47020_student_app/api/bracu_auth_manager.dart';
import 'package:cse47020_student_app/model/section_info.dart';

class StudentSchedule extends StatelessWidget {
  const StudentSchedule({super.key});

  Future<Map<String, List<Map<String, dynamic>>>> _loadSchedule() async {
    final jsonString = await BracuAuthManager().getStudentSchedule();
    if (jsonString == null) {
      throw Exception("No schedule data available");
    }

    final decoded = jsonDecode(jsonString) as List<dynamic>;
    final sections = decoded.map((e) => Section.fromJson(e)).toList();

    // Group schedules by day
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final section in sections) {
      for (final classSchedule in section.sectionSchedule.classSchedules) {
        grouped.putIfAbsent(classSchedule.day, () => []);
        grouped[classSchedule.day]!.add({
          "schedule": classSchedule,
          "courseCode": section.courseCode,
          "roomNumber": section.roomNumber,
        });
      }
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
        future: _loadSchedule(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final grouped = snapshot.data!;
          final keys = grouped.keys.toList();
          List<String> days = [
            "SATURDAY",
            "SUNDAY",
            "MONDAY",
            "TUESDAY",
            "WEDNESDAY",
            "THURSDAY",
            "FRIDAY",
          ];
          days = days.where((day) => keys.contains(day)).toList();

          return ListView(
            padding: const EdgeInsets.all(12),
            children: days.map((day) {
              final schedules = grouped[day]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day heading
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      day,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Classes of the day
                  ...schedules.map((entry) {
                    final s = entry["schedule"] as ClassSchedule;
                    final code = entry["courseCode"];
                    final room = entry["roomNumber"];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(
                          code,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "${s.startTime} - ${s.endTime}\nRoom $room",
                        ),
                        isThreeLine: true,
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
