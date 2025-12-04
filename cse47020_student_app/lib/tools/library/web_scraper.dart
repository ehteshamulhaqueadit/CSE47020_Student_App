import 'dart:async';
import 'package:webview_flutter/webview_flutter.dart';

enum ScraperMode { headless, headed }

class WebScraper {
  late WebViewController _controller;
  Completer<void>? _navigationCompleter;
  final ScraperMode mode;
  String? _currentUrl;

  WebScraper({this.mode = ScraperMode.headless});

  /// Initialize and return the WebViewController
  WebViewController buildController({
    Function(String url)? onPageFinished,
    Function(WebResourceError error)? onError,
  }) {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            _currentUrl = url;
            if (_navigationCompleter != null &&
                !_navigationCompleter!.isCompleted) {
              _navigationCompleter!.complete();
            }
            onPageFinished?.call(url);
          },
          onWebResourceError: (error) {
            if (_navigationCompleter != null &&
                !_navigationCompleter!.isCompleted) {
              _navigationCompleter!.completeError(error);
            }
            onError?.call(error);
          },
          onNavigationRequest: (request) {
            return NavigationDecision.navigate;
          },
        ),
      );
    return _controller;
  }

  /// Navigate to a URL and wait for page to load
  Future<void> visit(String url) async {
    _navigationCompleter = Completer<void>();
    await _controller.loadRequest(Uri.parse(url));
    return _navigationCompleter!.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw TimeoutException('Page load timeout');
      },
    );
  }

  /// Inject JavaScript and return result
  Future<dynamic> jsInject(String script) async {
    try {
      return await _controller.runJavaScriptReturningResult(script);
    } catch (e) {
      throw Exception('JavaScript injection failed: $e');
    }
  }

  /// Get the current page HTML
  Future<String> getHTML() async {
    final result = await jsInject("document.documentElement.outerHTML");
    return result.toString();
  }

  /// Check if an element exists on the page
  Future<bool> elementExists(String selector) async {
    try {
      final result = await jsInject(
        "document.querySelector('$selector') !== null",
      );
      return result.toString().toLowerCase() == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Get text content of an element
  Future<String?> getElementText(String selector) async {
    try {
      final result = await jsInject(
        "document.querySelector('$selector')?.textContent || ''",
      );
      return result.toString();
    } catch (e) {
      return null;
    }
  }

  /// Fill a form field
  Future<void> fillField(String fieldId, String value) async {
    await jsInject("""
      (function() {
        var field = document.getElementById('$fieldId');
        if (field) {
          field.value = '$value';
          return 'Field filled';
        }
        return 'Field not found';
      })();
    """);
  }

  /// Submit a form
  Future<void> submitForm(String formId) async {
    await jsInject("""
      (function() {
        var form = document.getElementById('$formId');
        if (form) {
          form.submit();
          return 'Form submitted';
        }
        return 'Form not found';
      })();
    """);
  }

  /// Wait for an element to appear
  Future<bool> waitForElement(
    String selector, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final startTime = DateTime.now();
    while (DateTime.now().difference(startTime) < timeout) {
      if (await elementExists(selector)) {
        return true;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return false;
  }

  bool get isHeadless => mode == ScraperMode.headless;
  bool get isHeaded => mode == ScraperMode.headed;

  WebViewController get controller => _controller;
  String? get currentUrl => _currentUrl;
}
