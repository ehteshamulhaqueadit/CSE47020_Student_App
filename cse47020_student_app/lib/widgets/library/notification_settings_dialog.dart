import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import 'borrowed_book_model.dart';

class NotificationSettingsDialog extends StatefulWidget {
  final BorrowedBook book;

  const NotificationSettingsDialog({super.key, required this.book});

  @override
  State<NotificationSettingsDialog> createState() =>
      _NotificationSettingsDialogState();
}

class _NotificationSettingsDialogState
    extends State<NotificationSettingsDialog> {
  final NotificationService _notificationService = NotificationService();
  bool _notificationEnabled = false;
  int _selectedHours = 24;
  bool _isLoading = true;

  final List<Map<String, dynamic>> _timeOptions = [
    {'label': '1 hour before', 'hours': 1},
    {'label': '3 hours before', 'hours': 3},
    {'label': '6 hours before', 'hours': 6},
    {'label': '12 hours before', 'hours': 12},
    {'label': '1 day before', 'hours': 24},
    {'label': '2 days before', 'hours': 48},
    {'label': '3 days before', 'hours': 72},
    {'label': '5 days before', 'hours': 120},
  ];

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final hours = await _notificationService.getBookNotificationHours(
      widget.book.itemId,
    );
    setState(() {
      _notificationEnabled = hours != null;
      if (hours != null) {
        _selectedHours = hours;
      }
      _isLoading = false;
    });
  }

  DateTime _parseDueDate() {
    try {
      // Try to parse the due date in DD/MM/YYYY format
      final parts = widget.book.dueDate.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (e) {
      print('Error parsing due date: $e');
    }
    // Fallback to 7 days from now if parsing fails
    return DateTime.now().add(const Duration(days: 7));
  }

  Future<void> _saveNotificationSettings() async {
    if (_notificationEnabled) {
      final dueDate = _parseDueDate();
      await _notificationService.scheduleBookReminder(
        bookId: widget.book.itemId,
        bookTitle: widget.book.title,
        dueDate: dueDate,
        hoursBeforeDue: _selectedHours,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Notification scheduled ${_timeOptions.firstWhere((opt) => opt['hours'] == _selectedHours)['label']}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      await _notificationService.cancelBookReminder(widget.book.itemId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
    if (mounted) {
      Navigator.pop(context, true); // Return true to indicate settings changed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: _isLoading
            ? const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade700, Colors.blue.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications_active,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Notification Settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.book,
                                  color: Colors.blue.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.book.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade900,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Due Date: ${widget.book.dueDate}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SwitchListTile(
                              value: _notificationEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _notificationEnabled = value;
                                });
                              },
                              title: const Text(
                                'Enable Reminder',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: const Text(
                                'Get notified before due date',
                              ),
                              activeColor: Colors.blue.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          if (_notificationEnabled) ...[
                            const SizedBox(height: 20),
                            Text(
                              'Notify me:',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: _timeOptions.map((option) {
                                  final isLast = option == _timeOptions.last;
                                  return Column(
                                    children: [
                                      RadioListTile<int>(
                                        value: option['hours'],
                                        groupValue: _selectedHours,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedHours = value!;
                                          });
                                        },
                                        title: Text(
                                          option['label'],
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        activeColor: Colors.blue.shade700,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 4,
                                            ),
                                      ),
                                      if (!isLast)
                                        Divider(
                                          height: 1,
                                          indent: 16,
                                          endIndent: 16,
                                          color: Colors.grey.shade200,
                                        ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // Footer buttons
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveNotificationSettings,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Save',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
