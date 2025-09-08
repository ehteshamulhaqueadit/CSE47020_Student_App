import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cse47020_student_app/api/bracu_auth_manager.dart';
import 'package:cse47020_student_app/model/section_info.dart';
import 'package:cse47020_student_app/tools/qrpainter.dart';

class ShareSchedulePage extends StatefulWidget {
  const ShareSchedulePage({super.key});

  @override
  State<ShareSchedulePage> createState() => _ShareSchedulePageState();
}

class _ShareSchedulePageState extends State<ShareSchedulePage> {
  String? _base64Data;
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAndConvertSchedule();
  }

  Future<void> _fetchAndConvertSchedule() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      _base64Data = null;
    });

    try {
      // Fetch student profile
      final profile = await BracuAuthManager().fetchProfile();
      final fullName = profile?['fullName'] ?? 'N/A';
      final studentId = profile?['studentId'] ?? 'N/A';

      // Fetch student schedule
      final jsonString = await BracuAuthManager().getStudentSchedule();
      if (jsonString == null) throw Exception("No schedule data available");

      final decoded = jsonDecode(jsonString) as List<dynamic>;
      final sections = decoded.map((e) => Section.fromJson(e)).toList();

      // Convert courses into a list of {courseCode, schedule}
      final courses = sections.map((section) {
        final schedules = section.sectionSchedule.classSchedules.map((c) {
          return {"day": c.day, "startTime": c.startTime, "endTime": c.endTime};
        }).toList();

        return {"courseCode": section.courseCode, "schedule": schedules};
      }).toList();

      // Build final JSON object
      final finalJson = {"name": fullName, "id": studentId, "courses": courses};

      // Convert to gzip + Base64
      final jsonStr = jsonEncode(finalJson);
      final utf8Bytes = utf8.encode(jsonStr);
      final gzipBytes = gzip.encode(utf8Bytes);
      final base64Str = base64.encode(gzipBytes);

      setState(() {
        _base64Data = base64Str;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? Center(child: Text("Error: $errorMessage"))
            : Column(
                children: [
                  if (_base64Data != null)
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(
                            20,
                          ), // adjust padding as needed
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final size = constraints
                                  .maxWidth; // max width of container
                              return CustomPaint(
                                size: Size.square(size),
                                painter: QrPainter(_base64Data!),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
