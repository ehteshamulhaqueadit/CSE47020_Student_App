import 'package:flutter/material.dart';
import 'borrowed_book_model.dart';

class BookCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.menu_book, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.author,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildDaysLeftBadge(),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: book.hasFines
                    ? Colors.red.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: book.hasFines
                        ? Colors.red.shade700
                        : Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Due: ${book.dueDate}',
                    style: TextStyle(
                      fontSize: 14,
                      color: book.hasFines
                          ? Colors.red.shade700
                          : Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.attach_money,
                    size: 18,
                    color: book.hasFines
                        ? Colors.red.shade700
                        : Colors.green.shade700,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: onShowDetails,
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text('Details'),
                ),
                ElevatedButton.icon(
                  onPressed: book.canRenew ? onRenew : null,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Renew'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    backgroundColor: book.canRenew ? Colors.blue : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaysLeftBadge() {
    final daysLeft = book.daysLeft;
    Color badgeColor = Colors.green;

    if (daysLeft < 0) {
      badgeColor = Colors.red;
    } else if (daysLeft <= 2) {
      badgeColor = Colors.orange;
    } else if (daysLeft <= 4) {
      badgeColor = Colors.yellow;
    } else {
      badgeColor = Colors.green;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          daysLeft < 0 ? 'Overdue' : '$daysLeft days',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: badgeColor,
          ),
        ),
        Text('left', style: TextStyle(fontSize: 12, color: badgeColor)),
      ],
    );
  }
}
