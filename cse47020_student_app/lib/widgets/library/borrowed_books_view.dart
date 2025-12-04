import 'package:flutter/material.dart';
import 'borrowed_book_model.dart';
import 'book_card.dart';

class BorrowedBooksView extends StatelessWidget {
  final List<BorrowedBook> borrowedBooks;
  final String loginMessage;
  final VoidCallback onRenewAll;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;
  final Function(BorrowedBook) onRenewBook;
  final Function(BorrowedBook) onShowDetails;

  const BorrowedBooksView({
    super.key,
    required this.borrowedBooks,
    required this.loginMessage,
    required this.onRenewAll,
    required this.onRefresh,
    required this.onLogout,
    required this.onRenewBook,
    required this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.book, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Borrowed Books',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Row(
              children: [
                if (borrowedBooks.any((book) => book.canRenew))
                  IconButton(
                    icon: const Icon(Icons.autorenew),
                    onPressed: onRenewAll,
                    tooltip: 'Renew All',
                    color: Colors.blue,
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: onRefresh,
                  tooltip: 'Refresh',
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: onLogout,
                  tooltip: 'Logout',
                ),
              ],
            ),
          ],
        ),
        if (loginMessage.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade900),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loginMessage,
                    style: TextStyle(color: Colors.green.shade900),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (borrowedBooks.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              children: [
                Icon(Icons.library_books, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No books currently borrowed',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 320,
            child: ListView.builder(
              itemCount: borrowedBooks.length,
              itemBuilder: (context, index) {
                final book = borrowedBooks[index];
                return BookCard(
                  book: book,
                  onRenew: () => onRenewBook(book),
                  onShowDetails: () => onShowDetails(book),
                );
              },
            ),
          ),
      ],
    );
  }
}
