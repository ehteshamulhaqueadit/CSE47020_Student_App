import 'package:flutter/material.dart';
import 'package:cse47020_student_app/api/bracu_auth_manager.dart';
import 'package:cse47020_student_app/pages/student_profile.dart';
import 'token_test.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  final List<Widget> pages = [TokenTest(), StudentProfile()];
  final List<String> titles = ['Token Test', 'Student Profile'];

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
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: Text('Token Test'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule),
            label: Text('Student Profile'),
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
