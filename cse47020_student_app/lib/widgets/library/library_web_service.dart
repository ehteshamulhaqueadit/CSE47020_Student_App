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
          // Wait for DOM to be ready
          if (document.readyState !== 'complete') {
            return JSON.stringify({success: false, message: 'Page still loading', pending: true});
          }
          
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
          
          // If page is still loading/transitioning, return pending status
          if (!bodyId && !bodyClass) {
            return JSON.stringify({success: false, message: 'Page loading...', pending: true});
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
      String resultStr = result.toString();

      // Clean up the JSON string
      String jsonStr = resultStr;
      if (jsonStr.startsWith('"') && jsonStr.endsWith('"')) {
        jsonStr = jsonStr.substring(1, jsonStr.length - 1);
        jsonStr = jsonStr.replaceAll(r'\', '');
      }

      // Try to parse as JSON
      try {
        final parsed = json.decode(jsonStr);
        return parsed;
      } catch (e) {
        // If JSON parsing fails but contains success indicators, assume success
        if (resultStr.contains('success') &&
            (resultStr.contains('true') || resultStr.contains('Clicked'))) {
          return {'success': true, 'message': 'Renew link clicked'};
        }
        return {
          'success': false,
          'message': 'Failed to parse result: $resultStr',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> verifyRenewal(
    WebViewController controller,
    BorrowedBook book,
  ) async {
    try {
      final verifyScript =
          '''
        (function() {
          // Check if we're on the user page with checkout table
          var checkoutTable = document.getElementById('checkoutst');
          if (!checkoutTable) {
            return JSON.stringify({
              success: false, 
              message: 'Checkout table not found',
              pending: true
            });
          }
          
          // Find the row for this specific item
          var rows = checkoutTable.querySelectorAll('tbody tr');
          var itemRow = null;
          
          rows.forEach(function(row) {
            var renewLink = row.querySelector('a[href*="item=${book.itemId}"]');
            if (renewLink) {
              itemRow = row;
            }
          });
          
          if (!itemRow) {
            return JSON.stringify({
              success: false,
              message: 'Item row not found',
              pending: true
            });
          }
          
          // Check for "Renewed!" success label - primary indicator
          var renewedLabel = itemRow.querySelector('.blabel.label-success');
          var hasRenewedLabel = renewedLabel && 
                                (renewedLabel.textContent.includes('Renewed') || 
                                 renewedLabel.textContent.includes('renewed'));
          
          // Also check for success messages in the renew cell
          var renewCell = itemRow.querySelector('.renew');
          var renewCellHasSuccess = renewCell && 
                                    renewCell.querySelector('.label-success');
          
          // Check for general success alert on the page
          var successAlert = document.querySelector('.alert-success');
          var hasSuccessAlert = successAlert && 
                                (successAlert.textContent.toLowerCase().includes('renewed') ||
                                 successAlert.textContent.toLowerCase().includes('success'));
          
          if (hasRenewedLabel || renewCellHasSuccess || hasSuccessAlert) {
            // Get updated renewal count
            var renewalsEl = itemRow.querySelector('.renewals');
            var renewalsText = 'N/A';
            if (renewalsEl) {
              var fullText = renewalsEl.textContent.trim();
              var match = fullText.match(/(\\d+)\\s+of\\s+(\\d+)/);
              if (match) {
                renewalsText = match[1] + ' of ' + match[2];
              }
            }
            
            return JSON.stringify({
              success: true,
              message: 'Book renewed successfully',
              renewalsRemaining: renewalsText
            });
          }
          
          // Check for error messages or alerts
          var alertError = itemRow.querySelector('.alert-error, .alert-danger');
          if (alertError) {
            return JSON.stringify({
              success: false,
              message: alertError.textContent.trim()
            });
          }
          
          // Check for "too many renewals" message
          var renewCell = itemRow.querySelector('.renew');
          if (renewCell) {
            var cellText = renewCell.textContent.toLowerCase();
            if (cellText.includes('not renewed') || 
                cellText.includes('cannot be renewed') ||
                cellText.includes('no renewals')) {
              return JSON.stringify({
                success: false,
                message: 'Item cannot be renewed: no renewals remaining'
              });
            }
          }
          
          // Check for general alert messages on the page
          var pageAlert = document.querySelector('.alert-warning, .alert-info');
          if (pageAlert) {
            var alertText = pageAlert.textContent.trim();
            if (alertText.includes('not renewed') || alertText.includes('error')) {
              return JSON.stringify({
                success: false,
                message: alertText
              });
            }
          }
          
          // If no clear success or failure, return pending
          return JSON.stringify({
            success: false,
            message: 'Renewal status unclear',
            pending: true
          });
        })();
      ''';

      final result = await controller.runJavaScriptReturningResult(
        verifyScript,
      );
      String resultStr = result.toString();

      String jsonStr = resultStr;
      if (jsonStr.startsWith('"') && jsonStr.endsWith('"')) {
        jsonStr = jsonStr.substring(1, jsonStr.length - 1);
        jsonStr = jsonStr.replaceAll(r'\', '');
      }

      return json.decode(jsonStr);
    } catch (e) {
      return {'success': false, 'message': 'Error verifying renewal: $e'};
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
      String resultStr = result.toString();

      // Clean up the JSON string
      String jsonStr = resultStr;
      if (jsonStr.startsWith('"') && jsonStr.endsWith('"')) {
        jsonStr = jsonStr.substring(1, jsonStr.length - 1);
        jsonStr = jsonStr.replaceAll(r'\', '');
      }

      // Try to parse as JSON
      try {
        final parsed = json.decode(jsonStr);
        return parsed;
      } catch (e) {
        // If JSON parsing fails but contains success indicators, assume success
        if (resultStr.contains('success') &&
            (resultStr.contains('true') ||
                resultStr.contains('Clicked') ||
                resultStr.contains('Submitted'))) {
          return {'success': true, 'message': 'Renew all clicked'};
        }
        return {
          'success': false,
          'message': 'Failed to parse result: $resultStr',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> verifyRenewAll(
    WebViewController controller,
  ) async {
    try {
      const verifyScript = '''
        (function() {
          var checkoutTable = document.getElementById('checkoutst');
          if (!checkoutTable) {
            return JSON.stringify({
              success: false,
              message: 'Checkout table not found',
              pending: true
            });
          }
          
          var rows = checkoutTable.querySelectorAll('tbody tr');
          var renewedCount = 0;
          var failedCount = 0;
          var totalCount = rows.length;
          
          rows.forEach(function(row) {
            var renewedLabel = row.querySelector('.blabel.label-success');
            if (renewedLabel && renewedLabel.textContent.includes('Renewed')) {
              renewedCount++;
            }
            
            var renewCell = row.querySelector('.renew');
            if (renewCell) {
              var cellText = renewCell.textContent.toLowerCase();
              if (cellText.includes('not renewed') || 
                  cellText.includes('cannot be renewed')) {
                failedCount++;
              }
            }
          });
          
          // Check for general success message
          var successAlert = document.querySelector('.alert-success, .alert-info');
          if (successAlert && successAlert.textContent.includes('renewed')) {
            return JSON.stringify({
              success: true,
              message: 'All books renewed successfully',
              renewedCount: renewedCount,
              totalCount: totalCount
            });
          }
          
          // If we see renewed labels, consider it a success
          if (renewedCount > 0) {
            var message = renewedCount + ' of ' + totalCount + ' books renewed';
            if (failedCount > 0) {
              message += ' (' + failedCount + ' failed)';
            }
            return JSON.stringify({
              success: true,
              message: message,
              renewedCount: renewedCount,
              failedCount: failedCount,
              totalCount: totalCount
            });
          }
          
          // Check for error messages
          var errorAlert = document.querySelector('.alert-error, .alert-danger');
          if (errorAlert) {
            return JSON.stringify({
              success: false,
              message: errorAlert.textContent.trim()
            });
          }
          
          return JSON.stringify({
            success: false,
            message: 'Unable to verify renewal status',
            pending: true
          });
        })();
      ''';

      final result = await controller.runJavaScriptReturningResult(
        verifyScript,
      );
      String resultStr = result.toString();

      String jsonStr = resultStr;
      if (jsonStr.startsWith('"') && jsonStr.endsWith('"')) {
        jsonStr = jsonStr.substring(1, jsonStr.length - 1);
        jsonStr = jsonStr.replaceAll(r'\', '');
      }

      return json.decode(jsonStr);
    } catch (e) {
      return {'success': false, 'message': 'Error verifying renew all: $e'};
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
