import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cse47020_student_app/model/friend_schedule.dart';

class FriendSchedulePage extends StatefulWidget {
  const FriendSchedulePage({super.key});

  @override
  State<FriendSchedulePage> createState() => _FriendSchedulePageState();
}

class _FriendSchedulePageState extends State<FriendSchedulePage> {
  List<FriendSchedule> decodedSchedules = [];

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? encodedList = prefs.getStringList("friendSchedules");

    if (encodedList == null) return;

    List<FriendSchedule> allSchedules = [];
    List<String> validEntries = [];

    for (final base64Json in encodedList) {
      try {
        final Uint8List decodeBase64Json = base64.decode(base64Json);
        final List<int> decodeGzipJson = gzip.decode(decodeBase64Json);
        final String originalJson = utf8.decode(decodeGzipJson);

        final parsed = jsonDecode(originalJson);
        allSchedules.add(FriendSchedule.fromJson(parsed));
        validEntries.add(base64Json); // keep valid entry
      } catch (e) {
        debugPrint("Skipping and deleting invalid entry: $e");
        // invalid entries are skipped
      }
    }

    // Save only valid entries
    await prefs.setStringList("friendSchedules", validEntries);

    setState(() {
      decodedSchedules = allSchedules;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Friend Schedule")),
      body: decodedSchedules.isEmpty
          ? const Center(child: Text("No schedules found"))
          : ListView.builder(
              itemCount: decodedSchedules.length,
              itemBuilder: (context, index) {
                final friend = decodedSchedules[index];

                return Card(
                  margin: const EdgeInsets.all(8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(friend.name,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          ...friend.courses.map((course) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("- ${course.courseCode}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  ...course.schedule.map((s) {
                                    return Text(
                                        "  ${s.day}: ${s.startTime} - ${s.endTime}");
                                  }).toList(),
                                ],
                              ),
                            );
                          }).toList(),
                        ]),
                  ),
                );
              },
            ),
    );
  }
}

