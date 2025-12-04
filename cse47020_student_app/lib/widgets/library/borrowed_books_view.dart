import 'package:flutter/material.dart';
import 'borrowed_book_model.dart';
import 'book_card.dart';

class BorrowedBooksView extends StatelessWidget {
  final List<BorrowedBook> borrowedBooks;
  final String loginMessage;
  final VoidCallback onRenewAll;
  final VoidCallback onLogout;
  final VoidCallback onRefresh;
  final Function(BorrowedBook) onRenewBook;
  final Function(BorrowedBook) onShowDetails;

  const BorrowedBooksView({
    super.key,
    required this.borrowedBooks,
    required this.loginMessage,
    required this.onRenewAll,
    required this.onLogout,
    required this.onRefresh,
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
            if (borrowedBooks.any((book) => book.canRenew))
              ElevatedButton.icon(
                icon: const Icon(Icons.autorenew),
                label: const Text('Renew All'),
                onPressed: onRenewAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              )
            else
              const SizedBox.shrink(),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: onRefresh,
              color: Colors.blue,
              iconSize: 28,
              tooltip: 'Refresh',
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              onPressed: onLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
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
