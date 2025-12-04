/// Model class for borrowed books
class BorrowedBook {
  final String title;
  final String author;
  final String dueDate;
  final String callNumber;
  final String renewalsRemaining;
  final String fines;
  final String itemId;
  final String borrowerNumber;

  BorrowedBook({
    required this.title,
    required this.author,
    required this.dueDate,
    required this.callNumber,
    required this.renewalsRemaining,
    required this.fines,
    required this.itemId,
    required this.borrowerNumber,
  });

  /// Check if the book has overdue fines
  bool get hasFines => fines.toLowerCase() != 'no' && fines.isNotEmpty;

  /// Check if the book can be renewed
  bool get canRenew {
    try {
      // Parse "21 of 30" format - extract first number
      final match = RegExp(r'(\d+)').firstMatch(renewalsRemaining);
      if (match != null) {
        final renewals = int.tryParse(match.group(1) ?? '0') ?? 0;
        return renewals > 0;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Parse days left until due date
  int get daysLeft {
    try {
      final parts = dueDate.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        final dueDateObj = DateTime(year, month, day);
        final now = DateTime.now();
        return dueDateObj
            .difference(DateTime(now.year, now.month, now.day))
            .inDays;
      }
    } catch (e) {
      print('Error parsing due date: $e');
    }
    return 0;
  }
}
