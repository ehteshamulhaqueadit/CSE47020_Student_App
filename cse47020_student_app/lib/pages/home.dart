import 'package:flutter/material.dart';
import 'package:cse47020_student_app/api/bracu_auth_manager.dart';
import 'package:cse47020_student_app/pages/student_profile.dart';
import 'package:cse47020_student_app/pages/student_schedule.dart';
import 'package:cse47020_student_app/pages/exam_schedule.dart';
import 'package:cse47020_student_app/pages/alarms.dart';
import 'package:cse47020_student_app/pages/share_schedule.dart';
import 'package:cse47020_student_app/pages/scan_schedule.dart';
import 'package:cse47020_student_app/pages/friend_schedule.dart';
import 'package:cse47020_student_app/pages/advising_info.dart';
import 'package:cse47020_student_app/pages/library.dart';
import 'token_test.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  final List<Widget> pages = [
    TokenTest(),
    StudentProfile(),
    StudentSchedule(),
    ExamSchedule(),
    AlarmPage(),
    ShareSchedulePage(),
    ScanSchedulePage(),
    FriendSchedulePage(),
    AdvisingInfoPage(),
    LibraryPage(),
  ];
  final List<String> titles = [
    'Token Test',
    'Student Profile',
    'Student Schedule',
    'Exam Schedule',
    'Set Alarms',
    'Share Class Schedule',
    'Scan Schedule',
    'Friends Availablity',
    'Advising Reminder',
    'Library',
  ];

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      BracuAuthManager().logout();
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[selectedIndex]),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: NavigationDrawer(
        selectedIndex: selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            selectedIndex = index;
          });
          Navigator.pop(context); // close drawer
        },
        children: [
          const NavigationDrawerDestination(
            icon: Icon(Icons.code_outlined),
            selectedIcon: Icon(Icons.code),
            label: Text('Token Test'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: Text('Student Profile'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: Text('Student Schedule'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: Text('Exam Schedule'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.alarm_outlined),
            selectedIcon: Icon(Icons.alarm),
            label: Text('Set Alarms'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.share_outlined),
            selectedIcon: Icon(Icons.share),
            label: Text('Share Class Schedule'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner),
            label: Text('Scan Schedule Page'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: Text('Friends Availablity'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: Text('Advising Reminder'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.local_library_outlined),
            selectedIcon: Icon(Icons.local_library),
            label: Text('Library'),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 28, vertical: 8),
            child: Divider(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () => _confirmLogout(context),
            ),
          ),
        ],
      ),
      body: pages[selectedIndex],
    );
  }
}
