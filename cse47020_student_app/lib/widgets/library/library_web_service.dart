import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
import 'borrowed_book_model.dart';

class LibraryWebService {
  static const String libraryUrl =
      'https://library.bracu.ac.bd/cgi-bin/koha/opac-user.pl';

  static Future<Map<String, dynamic>> checkIfLoggedIn(
    WebViewController controller,
  ) async {
    try {
      const checkScript = '''
        (function() {
          // Check multiple indicators of being logged in
          var bodyId = document.body.getAttribute('id') || document.body.getAttribute('ID') || '';
          var bodyClass = document.body.className || '';
          bodyId = bodyId.toLowerCase();
          
          var isLoggedIn = bodyId === 'opac-user' || 
                          bodyClass.includes('logged-in') ||
                          document.querySelector('.loggedinusername') !== null ||
                          document.querySelector('#checkoutst') !== null ||
                          document.querySelector('.patron-info') !== null;
          
          if (isLoggedIn) {
            var userName = document.querySelector('.loggedinusername');
            var checkoutTable = document.getElementById('checkoutst');
            return JSON.stringify({
              loggedIn: true,
              userName: userName ? userName.textContent.trim() : '',
              hasBooks: checkoutTable !== null
            });
          }
          
          return JSON.stringify({loggedIn: false});
        })();
      ''';

      final result = await controller.runJavaScriptReturningResult(checkScript);
      final resultStr = result.toString();

      String jsonStr = resultStr;
      if (jsonStr.startsWith('"') && jsonStr.endsWith('"')) {
        jsonStr = jsonStr.substring(1, jsonStr.length - 1);
        jsonStr = jsonStr.replaceAll(r'\', '');
      }

      return json.decode(jsonStr);
    } catch (e) {
      return {'loggedIn': false, 'error': e.toString()};
    }
  }

  static Future<void> submitLoginForm(
    WebViewController controller,
    String userid,
    String password,
  ) async {
    final script =
        '''
      (function() {
        var useridField = document.getElementById('userid');
        var passwordField = document.getElementById('password');
        var form = document.getElementById('auth');
        
        if (useridField && passwordField && form) {
          useridField.value = '$userid';
          passwordField.value = '$password';
          form.submit();
          return 'Login form submitted';
        } else {
          return 'Login form not found';
        }
      })();
    ''';

    await controller.runJavaScriptReturningResult(script);
  }

  static Future<Map<String, dynamic>> checkLoginStatus(
    WebViewController controller,
  ) async {
    try {
      const checkScript = '''
        (function() {
          var bodyId = document.body.getAttribute('id') || document.body.getAttribute('ID') || '';
          var bodyClass = document.body.className || '';
          bodyId = bodyId.toLowerCase();
          
          var isLoggedIn = bodyId === 'opac-user' || 
                          bodyClass.includes('logged-in') ||
                          document.querySelector('.loggedinusername') !== null ||
                          document.querySelector('#checkoutst') !== null ||
                          document.querySelector('.patron-info') !== null;
          
          if (isLoggedIn) {
            var checkoutTable = document.getElementById('checkoutst');
            var userName = document.querySelector('.loggedinusername');
            return JSON.stringify({
              success: true,
              hasBooks: checkoutTable !== null,
              userName: userName ? userName.textContent.trim() : '',
              bodyId: bodyId,
              bodyClass: bodyClass
            });
          } 
          
          var isLoginPage = bodyId === 'opac-login-page' || 
                           document.getElementById('auth') !== null ||
                           document.getElementById('userid') !== null;
          
          if (isLoginPage) {
            var errorAlert = document.querySelector('.alert.alert-info');
            var errorMsg = 'Login failed';
            if (errorAlert) {
              errorMsg = errorAlert.textContent.includes('incorrect') 
                ? 'Incorrect username or password' 
                : errorAlert.textContent.trim();
            }
            return JSON.stringify({success: false, message: errorMsg, bodyId: bodyId});
          }
          
          return JSON.stringify({
            success: false, 
            message: 'Unknown page state. bodyId: ' + bodyId + ', bodyClass: ' + bodyClass,
            bodyId: bodyId,
            bodyClass: bodyClass
          });
        })();
      ''';

      final result = await controller.runJavaScriptReturningResult(checkScript);
      String resultStr = result.toString();

      String jsonStr = resultStr;
      if (jsonStr.startsWith('"') && jsonStr.endsWith('"')) {
        jsonStr = jsonStr.substring(1, jsonStr.length - 1);
        jsonStr = jsonStr.replaceAll(r'\', '');
      }

      return json.decode(jsonStr);
    } catch (e) {
      return {'success': false, 'message': 'Error checking login: $e'};
    }
  }

  static Future<List<BorrowedBook>> parseBorrowedBooks(
    WebViewController controller,
  ) async {
    try {
      const checkTableScript = "document.getElementById('checkoutst') !== null";
      final hasTableResult = await controller.runJavaScriptReturningResult(
        checkTableScript,
      );
      final hasTable = hasTableResult.toString().toLowerCase() == 'true';

      if (!hasTable) {
        return [];
      }

      const parseScript = '''
        (function() {
          var books = [];
          var checkoutTable = document.getElementById('checkoutst');
          if (!checkoutTable) return JSON.stringify([]);
          
          var rows = checkoutTable.querySelectorAll('tbody tr');
          rows.forEach(function(row) {
            var titleEl = row.querySelector('.title .biblio-title');
            var authorEl = row.querySelector('.author');
            var dueDateEl = row.querySelector('.date_due');
            var callNumberEl = row.querySelector('.call_no');
            var renewalsEl = row.querySelector('.renewals');
            var finesEl = row.querySelector('.fines span');
            var renewLinkEl = row.querySelector('.renew a');
            
            if (titleEl) {
              var renewalsText = 'N/A';
              if (renewalsEl) {
                var fullText = renewalsEl.textContent.trim();
                var match = fullText.match(/(\\d+)\\s+of\\s+(\\d+)/);
                if (match) {
                  renewalsText = match[1] + ' of ' + match[2];
                } else {
                  renewalsText = fullText.replace(/[\\n\\r()]/g, '').trim();
                }
              }
              
              var finesText = 'No';
              if (finesEl) {
                finesText = finesEl.textContent.trim();
                finesText = finesText.replace(/^Fines:\\s*/i, '');
              }
              
              var book = {
                title: titleEl.textContent.trim(),
                author: authorEl ? authorEl.textContent.trim() : 'Unknown',
                dueDate: dueDateEl ? dueDateEl.textContent.replace('Date due:', '').trim() : '',
                callNumber: callNumberEl ? callNumberEl.textContent.replace('Call number:', '').trim() : '',
                renewalsRemaining: renewalsText,
                fines: finesText,
                itemId: '',
                borrowerNumber: ''
              };
              
              if (renewLinkEl) {
                var href = renewLinkEl.getAttribute('href');
                var itemMatch = href.match(/item=(\\d+)/);
                var borrowerMatch = href.match(/borrowernumber=(\\d+)/);
                book.itemId = itemMatch ? itemMatch[1] : '';
                book.borrowerNumber = borrowerMatch ? borrowerMatch[1] : '';
              }
              
              books.push(book);
            }
          });
          
          return JSON.stringify(books);
        })();
      ''';

      final result = await controller.runJavaScriptReturningResult(parseScript);
      String resultStr = result.toString();

      if (resultStr.startsWith('"') && resultStr.endsWith('"')) {
        resultStr = resultStr.substring(1, resultStr.length - 1);
        resultStr = resultStr.replaceAll(r'\', '');
      }

      final List<dynamic> jsonBooks = json.decode(resultStr);
      return jsonBooks.map((book) {
        return BorrowedBook(
          title: book['title'] ?? '',
          author: book['author'] ?? 'Unknown',
          dueDate: book['dueDate'] ?? '',
          callNumber: book['callNumber'] ?? '',
          renewalsRemaining: book['renewalsRemaining'] ?? 'N/A',
          fines: book['fines'] ?? 'No',
          itemId: book['itemId'] ?? '',
          borrowerNumber: book['borrowerNumber'] ?? '',
        );
      }).toList();
    } catch (e) {
      print('Error parsing books: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> renewBook(
    WebViewController controller,
    BorrowedBook book,
  ) async {
    try {
      final renewScript =
          '''
        (function() {
          var renewLink = document.querySelector('a[href*="opac-renew.pl"][href*="item=${book.itemId}"][href*="borrowernumber=${book.borrowerNumber}"]');
          
          if (renewLink) {
            renewLink.click();
            return JSON.stringify({success: true, message: 'Clicked renew link'});
          }
          
          var fallbackLink = document.querySelector('.renew a[href*="item=${book.itemId}"]');
          if (fallbackLink) {
            fallbackLink.click();
            return JSON.stringify({success: true, message: 'Clicked fallback renew link'});
          }
          
          return JSON.stringify({success: false, message: 'Renew link not found'});
        })();
      ''';

      final result = await controller.runJavaScriptReturningResult(renewScript);
      final resultStr = result.toString();

      if (resultStr.contains('success":true') ||
          resultStr.contains('success:true')) {
        return {'success': true};
      } else {
        return {'success': false, 'message': 'Failed to find renew link'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> renewAllBooks(
    WebViewController controller,
  ) async {
    try {
      const renewAllScript = '''
        (function() {
          var renewAllButton = document.querySelector('#renewall_link') ||
                              document.querySelector('#renewall_js') ||
                              document.querySelector('button[id*="renewall"]') ||
                              document.querySelector('.buttons-renewall');
          
          if (renewAllButton) {
            renewAllButton.click();
            return JSON.stringify({success: true, message: 'Clicked renew all button'});
          }
          
          var renewAllForm = document.querySelector('#renewall');
          if (renewAllForm) {
            renewAllForm.submit();
            return JSON.stringify({success: true, message: 'Submitted renew all form'});
          }
          
          return JSON.stringify({success: false, message: 'Renew all button not found'});
        })();
      ''';

      final result = await controller.runJavaScriptReturningResult(
        renewAllScript,
      );
      final resultStr = result.toString();

      if (resultStr.contains('success":true') ||
          resultStr.contains('success:true')) {
        return {'success': true};
      } else {
        return {'success': false, 'message': 'Failed to find renew all button'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> logout(
    WebViewController controller,
  ) async {
    try {
      const logoutScript = '''
        (function() {
          var logoutLink = document.querySelector('#logout') ||
                          document.querySelector('a[href*="logout.x=1"]') ||
                          document.querySelector('.logout');
          
          if (logoutLink) {
            logoutLink.click();
            return JSON.stringify({success: true, message: 'Logout clicked'});
          }
          return JSON.stringify({success: false, message: 'Logout link not found'});
        })();
      ''';

      final result = await controller.runJavaScriptReturningResult(
        logoutScript,
      );
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
