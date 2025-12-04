import 'package:flutter/material.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Library',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildLibraryCard(
                    context,
                    title: 'Book Search',
                    subtitle: 'Search for available books',
                    icon: Icons.search,
                    onTap: () {
                      // TODO: Implement book search
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Book search feature coming soon'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildLibraryCard(
                    context,
                    title: 'My Borrowed Books',
                    subtitle: 'View your currently borrowed books',
                    icon: Icons.book,
                    onTap: () {
                      // TODO: Implement borrowed books view
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Borrowed books feature coming soon'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildLibraryCard(
                    context,
                    title: 'Library Hours',
                    subtitle: 'Check library operating hours',
                    icon: Icons.access_time,
                    onTap: () {
                      // TODO: Implement library hours
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Library hours feature coming soon'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildLibraryCard(
                    context,
                    title: 'Reserve a Seat',
                    subtitle: 'Reserve a study seat in the library',
                    icon: Icons.event_seat,
                    onTap: () {
                      // TODO: Implement seat reservation
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Seat reservation feature coming soon'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
