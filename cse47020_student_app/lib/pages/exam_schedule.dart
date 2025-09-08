import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cse47020_student_app/api/bracu_auth_manager.dart';
import 'package:cse47020_student_app/model/section_info.dart';

class ExamSchedule extends StatelessWidget {
  const ExamSchedule({super.key});

  Future<List<Section>> _fetchExamSections() async {
    final jsonString = await BracuAuthManager().getStudentSchedule();
    if (jsonString == null) {
      throw Exception("No schedule data available");
    }

    final decoded = jsonDecode(jsonString) as List<dynamic>;
    return decoded.map((e) => Section.fromJson(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Section>>(
        future: _fetchExamSections(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No exam data available'));
          }

          final sections = snapshot.data!;

          // Filter only sections with mid or final exams
          final exams = sections.where(
            (s) =>
                (s.sectionSchedule.midExamDate != null &&
                    s.sectionSchedule.midExamStartTime != null) ||
                (s.sectionSchedule.finalExamDate != null &&
                    s.sectionSchedule.finalExamStartTime != null),
          );

          return ListView.builder(
            itemCount: exams.length,
            itemBuilder: (context, index) {
              final section = exams.elementAt(index);
              final schedule = section.sectionSchedule;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${section.courseCode} - ${section.sectionName}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (schedule.midExamDate != null)
                        Text(
                          'Midterm: ${schedule.midExamDate} | ${schedule.midExamStartTime} - ${schedule.midExamEndTime}',
                        ),
                      if (schedule.finalExamDate != null)
                        Text(
                          'Final: ${schedule.finalExamDate} | ${schedule.finalExamStartTime} - ${schedule.finalExamEndTime}',
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
