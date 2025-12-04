import 'package:flutter/material.dart';
import 'borrowed_book_model.dart';

class BookDetailsDialog extends StatelessWidget {
  final BorrowedBook book;
  final VoidCallback onRenew;

  const BookDetailsDialog({
    super.key,
    required this.book,
    required this.onRenew,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.menu_book, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(book.title, style: const TextStyle(fontSize: 18)),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Author', book.author, Icons.person),
            _buildDetailRow(
              'Due Date',
              book.dueDate,
              Icons.calendar_today,
              color: book.hasFines ? Colors.red : Colors.orange,
            ),
            _buildDetailRow('Call Number', book.callNumber, Icons.tag),
            _buildDetailRow(
              'Renewals Remaining',
              book.renewalsRemaining,
              Icons.refresh,
              color: book.canRenew ? Colors.green : Colors.grey,
            ),
            _buildDetailRow(
              'Fines',
              book.hasFines ? 'Yes' : 'No',
              Icons.attach_money,
              color: book.hasFines ? Colors.red : Colors.green,
            ),
            if (book.itemId.isNotEmpty)
              _buildDetailRow('Item ID', book.itemId, Icons.numbers),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton.icon(
          onPressed: book.canRenew
              ? () {
                  Navigator.pop(context);
                  onRenew();
                }
              : null,
          icon: const Icon(Icons.refresh),
          label: const Text('Renew'),
          style: ElevatedButton.styleFrom(
            backgroundColor: book.canRenew ? Colors.blue : Colors.grey,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: color ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
