import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../widgets/library/borrowed_book_model.dart';
import '../widgets/library/library_login_form.dart';
import '../widgets/library/borrowed_books_view.dart';
import '../widgets/library/book_details_dialog.dart';
import '../widgets/library/library_web_service.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage>
    with SingleTickerProviderStateMixin {
  late WebViewController _controller;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // State management
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String _loginMessage = '';
  String _errorMessage = '';
  List<BorrowedBook> _borrowedBooks = [];
  bool _waitingForLoginResponse = false;
  bool _waitingForRenewalResponse = false;
  BorrowedBook? _bookBeingRenewed;
  bool _isInitialLogin = false; // Track if this is user-initiated login

  // Form controllers
  final TextEditingController _useridController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _initializeController();
    _loadLibraryPage();
  }

  void _initializeController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) => _handlePageFinished(url),
          onWebResourceError: (error) => _handleWebError(error),
          onNavigationRequest: (request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
      );
  }

  Future<void> _handlePageFinished(String url) async {
    if (_waitingForLoginResponse) {
      _waitingForLoginResponse = false;
      // Longer delay to ensure page is fully rendered after login
      await Future.delayed(const Duration(seconds: 2));
      await _checkLoginStatus();
    }

    if (_waitingForRenewalResponse && _bookBeingRenewed != null) {
      // Page has reloaded after renewal, give it a moment to render
      await Future.delayed(const Duration(milliseconds: 500));
      await _verifyRenewalWithRetries(_bookBeingRenewed!);
    }
  }

  void _handleWebError(WebResourceError error) {
    // Ignore common resource loading errors (images, css, js files)
    // Only show critical navigation errors
    if (error.errorType == WebResourceErrorType.hostLookup ||
        error.errorType == WebResourceErrorType.timeout ||
        error.errorType == WebResourceErrorType.connect) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Connection error: ${error.description}';
          _isLoading = false;
        });
      }
    }
    // Log other errors but don't display them
    print('WebView resource error (ignored): ${error.description}');
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _useridController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadLibraryPage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _controller.loadRequest(Uri.parse(LibraryWebService.libraryUrl));
      await Future.delayed(const Duration(seconds: 2));
      await _checkIfAlreadyLoggedIn();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load library page: $e';
        });
        _showSnackBar('Error loading library page: $e');
      }
    }
  }

  Future<void> _checkIfAlreadyLoggedIn() async {
    try {
      final status = await LibraryWebService.checkIfLoggedIn(_controller);
      if (status['loggedIn'] == true) {
        await _parseBorrowedBooks(showSuccessMessage: false);
      }
    } catch (e) {
      print('Error checking login status: $e');
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _autoLogin() async {
    final userid = _useridController.text.trim();
    final password = _passwordController.text.trim();

    if (userid.isEmpty || password.isEmpty) {
      _showSnackBar('Please enter both userid and password');
      return;
    }

    setState(() {
      _isLoading = true;
      _waitingForLoginResponse = true;
      _isInitialLogin = true; // User is actively logging in
      _loginMessage = 'Logging in...';
      _errorMessage = '';
    });

    try {
      await LibraryWebService.submitLoginForm(_controller, userid, password);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _waitingForLoginResponse = false;
          _isLoggedIn = false;
          _loginMessage = 'Error during login: $e';
        });
        _showSnackBar('Login error: $e');
      }
    }
  }

  Future<void> _checkLoginStatus() async {
    try {
      var status = await LibraryWebService.checkLoginStatus(_controller);

      // If page is still loading, wait and retry once
      if (status['pending'] == true) {
        await Future.delayed(const Duration(seconds: 1));
        status = await LibraryWebService.checkLoginStatus(_controller);
      }

      if (status['success'] == true) {
        await _parseBorrowedBooks(showSuccessMessage: _isInitialLogin);
      } else {
        // Don't show error if page is still pending after retry
        if (status['pending'] != true && mounted) {
          setState(() {
            _isLoading = false;
            _isLoggedIn = false;
            _loginMessage = status['message'] ?? 'Login failed';
            _borrowedBooks = [];
          });
          // Only show login failed message if this was an initial login attempt
          if (_isInitialLogin) {
            _showSnackBar(status['message'] ?? 'Login failed');
          }
          _isInitialLogin = false;
        } else if (mounted) {
          // Page still loading after retry, just stop the loading indicator
          setState(() {
            _isLoading = false;
            _isInitialLogin = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoggedIn = false;
          _loginMessage = 'Error checking login: $e';
        });
        // Only show error if this was an initial login attempt
        if (_isInitialLogin) {
          _showSnackBar('Error checking login: $e');
        }
        _isInitialLogin = false;
      }
    }
  }

  Future<void> _parseBorrowedBooks({bool showSuccessMessage = false}) async {
    try {
      final books = await LibraryWebService.parseBorrowedBooks(_controller);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoggedIn = true;
          _borrowedBooks = books;
          _loginMessage = books.isEmpty
              ? 'Login successful! No books currently borrowed.'
              : 'Login successful! ${books.length} book(s) borrowed.';
          // Reset initial login flag after processing
          _isInitialLogin = false;
        });

        // Only show success message if this is the initial login
        if (showSuccessMessage) {
          _showSnackBar(_loginMessage, isError: false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoggedIn = false;
          _loginMessage = 'Error parsing books: $e';
          _isInitialLogin = false;
        });
        _showSnackBar('Error parsing books: $e');
      }
    }
  }

  Future<void> _renewBook(BorrowedBook book) async {
    if (!book.canRenew) {
      _showSnackBar('This book cannot be renewed. No renewals remaining.');
      return;
    }

    if (book.itemId.isEmpty || book.borrowerNumber.isEmpty) {
      _showSnackBar('Missing renewal information for this book.');
      return;
    }

    setState(() {
      _isLoading = true;
      _waitingForRenewalResponse = true;
      _bookBeingRenewed = book;
    });

    try {
      // Click the renew link
      final clickResult = await LibraryWebService.renewBook(_controller, book);

      if (clickResult['success'] != true) {
        setState(() {
          _waitingForRenewalResponse = false;
          _bookBeingRenewed = null;
        });
        throw Exception(clickResult['message'] ?? 'Failed to click renew link');
      }

      _showSnackBar('Renewing "${book.title}"...', isError: false);

      // The verification will happen in _handlePageFinished when the page reloads
      // Set a timeout in case the page doesn't reload
      Future.delayed(const Duration(seconds: 10), () {
        if (_waitingForRenewalResponse && mounted) {
          _verifyRenewalWithRetries(book);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _waitingForRenewalResponse = false;
          _bookBeingRenewed = null;
        });
        _showSnackBar('Error renewing book: $e');
      }
    }
  }

  Future<void> _verifyRenewalWithRetries(BorrowedBook book) async {
    if (!_waitingForRenewalResponse || !mounted) return;

    const maxRetries = 5;
    const retryDelays = [500, 1000, 1500, 2000, 3000]; // milliseconds

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final verifyResult = await LibraryWebService.verifyRenewal(
          _controller,
          book,
        );

        // If we got a definitive result (success or failure), process it
        if (verifyResult['pending'] != true) {
          if (mounted) {
            setState(() {
              _waitingForRenewalResponse = false;
              _bookBeingRenewed = null;
            });
          }

          if (verifyResult['success'] == true) {
            // Refresh the book list silently to show updated renewal count
            await _parseBorrowedBooks(showSuccessMessage: false);
            if (mounted) {
              _showSnackBar('Book renewed successfully!', isError: false);
            }
          } else {
            if (mounted) {
              setState(() => _isLoading = false);
              _showSnackBar(
                verifyResult['message'] ?? 'Failed to verify renewal',
              );
            }
          }
          return;
        }

        // If pending and not the last attempt, wait before retrying
        if (attempt < maxRetries - 1) {
          await Future.delayed(Duration(milliseconds: retryDelays[attempt]));
        }
      } catch (e) {
        print('Renewal verification attempt ${attempt + 1} failed: $e');
        if (attempt == maxRetries - 1) {
          // Last attempt failed
          if (mounted) {
            setState(() {
              _isLoading = false;
              _waitingForRenewalResponse = false;
              _bookBeingRenewed = null;
            });
            _showSnackBar(
              'Could not verify renewal status. Please refresh to check.',
            );
          }
        } else {
          await Future.delayed(Duration(milliseconds: retryDelays[attempt]));
        }
      }
    }

    // All retries exhausted
    if (mounted) {
      setState(() {
        _isLoading = false;
        _waitingForRenewalResponse = false;
        _bookBeingRenewed = null;
      });
      _showSnackBar(
        'Could not verify renewal status. Please refresh to check.',
      );
    }
  }

  Future<void> _renewAllBooks() async {
    final renewableBooks = _borrowedBooks
        .where((book) => book.canRenew)
        .toList();

    if (renewableBooks.isEmpty) {
      _showSnackBar('No books available for renewal.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renew All Books'),
        content: Text(
          'Are you sure you want to renew all ${renewableBooks.length} renewable book(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Renew All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Click the renew all button
      final clickResult = await LibraryWebService.renewAllBooks(_controller);

      if (clickResult['success'] != true) {
        throw Exception(
          clickResult['message'] ?? 'Failed to click renew all button',
        );
      }

      _showSnackBar('Renewing all books...', isError: false);

      // Wait for page to reload after clicking renew all
      await Future.delayed(const Duration(seconds: 3));

      // Verify renewal success
      var verifyResult = await LibraryWebService.verifyRenewAll(_controller);

      // If pending, wait a bit more and retry verification
      if (verifyResult['pending'] == true) {
        await Future.delayed(const Duration(seconds: 1));
        verifyResult = await LibraryWebService.verifyRenewAll(_controller);
      }

      if (verifyResult['success'] == true) {
        // Refresh the book list silently to show updated renewal counts
        await _parseBorrowedBooks(showSuccessMessage: false);

        final renewedCount =
            verifyResult['renewedCount'] ?? renewableBooks.length;
        final failedCount = verifyResult['failedCount'] ?? 0;

        String message;
        if (failedCount > 0) {
          message =
              '$renewedCount book(s) renewed successfully, $failedCount failed';
        } else {
          message = 'All books renewed successfully!';
        }
        _showSnackBar(message, isError: failedCount > 0);
      } else {
        throw Exception(verifyResult['message'] ?? 'Failed to verify renewal');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Error renewing all books: $e');
      }
    }
  }

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await LibraryWebService.logout(_controller);
      await Future.delayed(const Duration(seconds: 2));

      _isLoggedIn = false;
      _borrowedBooks = [];
      _loginMessage = '';
      _useridController.clear();
      _passwordController.clear();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Logged out successfully', isError: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Error logging out: $e');
      }
    }
  }

  Widget _buildLoginForm() {
    return LibraryLoginForm(
      useridController: _useridController,
      passwordController: _passwordController,
      onLogin: _autoLogin,
      isLoading: _isLoading,
      isLoggedIn: _isLoggedIn,
      loginMessage: _loginMessage,
      errorMessage: _errorMessage,
    );
  }

  Widget _buildBorrowedBooksView() {
    return BorrowedBooksView(
      borrowedBooks: _borrowedBooks,
      loginMessage: _loginMessage,
      onRenewAll: _renewAllBooks,
      onLogout: _logout,
      onRefresh: _refreshBooks,
      onRenewBook: _renewBook,
      onShowDetails: _showBookDetails,
    );
  }

  Future<void> _refreshBooks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _controller.reload();
      await Future.delayed(const Duration(seconds: 2));
      await _parseBorrowedBooks(showSuccessMessage: false);
      _showSnackBar('Books refreshed', isError: false);
    } catch (e) {
      _showSnackBar('Error refreshing: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showBookDetails(BorrowedBook book) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Book Details',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return BookDetailsDialog(book: book, onRenew: () => _renewBook(book));
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(opacity: curvedAnimation, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: _isLoggedIn
                            ? _buildBorrowedBooksView()
                            : Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 360,
                                  ),
                                  child: _buildLoginForm(),
                                ),
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue.shade600,
                          ),
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading...',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
