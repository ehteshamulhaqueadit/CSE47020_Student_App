import 'package:flutter/material.dart';
import 'borrowed_book_model.dart';
import '../../services/notification_service.dart';
import 'notification_settings_dialog.dart';

class BookCard extends StatefulWidget {
  final BorrowedBook book;
  final VoidCallback onRenew;
  final VoidCallback onShowDetails;

  const BookCard({
    super.key,
    required this.book,
    required this.onRenew,
    required this.onShowDetails,
  });

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard> {
  final NotificationService _notificationService = NotificationService();
  bool _hasNotification = false;

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    final hours = await _notificationService.getBookNotificationHours(
      widget.book.itemId,
    );
    if (mounted) {
      setState(() {
        _hasNotification = hours != null;
      });
    }
  }

  Future<void> _showNotificationSettings() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => NotificationSettingsDialog(book: widget.book),
    );

    // Refresh notification status if settings were changed
    if (result == true && mounted) {
      await _checkNotificationStatus();
    }
  }

  /// Reschedules notification after book renewal with updated due date
  Future<void> rescheduleNotification() async {
    final hours = await _notificationService.getBookNotificationHours(
      widget.book.itemId,
    );
    if (hours != null) {
      // Notification was set, reschedule with new due date
      await _notificationService.scheduleBookReminder(
        bookId: widget.book.itemId,
        bookTitle: widget.book.title,
        dueDate: _parseDueDate(widget.book.dueDate),
        hoursBeforeDue: hours,
      );
      await _checkNotificationStatus();
    }
  }

  DateTime _parseDueDate(String dueDateStr) {
    try {
      final parts = dueDateStr.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]), // year
          int.parse(parts[1]), // month
          int.parse(parts[0]), // day
        );
      }
    } catch (e) {
      print('Error parsing due date: $e');
    }
    return DateTime.now().add(const Duration(days: 7));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.book.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.book.author,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildDaysLeftBadge(),
                const SizedBox(width: 8),
                Icon(
                  Icons.attach_money,
                  size: 24,
                  color: widget.book.hasFines ? Colors.red : Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.book.dueDate,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const Spacer(),
                if (widget.book.hasFines)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Has Fines',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Notification bell button
                IconButton(
                  onPressed: _showNotificationSettings,
                  icon: Icon(
                    _hasNotification
                        ? Icons.notifications_active
                        : Icons.notifications_outlined,
                    size: 20,
                  ),
                  style: IconButton.styleFrom(
                    foregroundColor: _hasNotification
                        ? Colors.blue.shade700
                        : Colors.grey.shade600,
                    backgroundColor: _hasNotification
                        ? Colors.blue.shade50
                        : Colors.grey.shade100,
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(36, 36),
                  ),
                  tooltip: 'Set Reminder',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onShowDetails,
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('Details'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      foregroundColor: Colors.blue.shade700,
                      side: BorderSide(color: Colors.blue.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                if (widget.book.canRenew) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      onPressed: widget.onRenew,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        foregroundColor: Colors.blue.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Renew '),
                          Text(
                            '(${widget.book.renewalsLeft})',
                            style: TextStyle(
                              color: widget.book.renewalsLeft < 10
                                  ? Colors.red
                                  : Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaysLeftBadge() {
    final daysLeft = widget.book.daysLeft;
    Color badgeColor;
    String text;

    if (daysLeft < 0) {
      badgeColor = Colors.red.shade600;
      text = 'Overdue';
    } else if (daysLeft == 0) {
      badgeColor = Colors.red.shade600;
      text = 'Due Today';
    } else if (daysLeft <= 2) {
      badgeColor = Colors.red.shade600;
      text = '$daysLeft days';
    } else if (daysLeft <= 4) {
      badgeColor = Colors.orange.shade600;
      text = '$daysLeft days';
    } else if (daysLeft <= 5) {
      badgeColor = Colors.green.shade600;
      text = '$daysLeft days';
    } else {
      badgeColor = Colors.grey.shade600;
      text = '$daysLeft days';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: badgeColor,
        ),
      ),
    );
  }
}
