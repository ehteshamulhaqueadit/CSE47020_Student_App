import 'dart:async';
import 'package:webview_flutter/webview_flutter.dart';

class WebScraper {
  late WebViewController _controller;
  Completer<void> _pageLoaded = Completer<void>();
  bool _isLoaded = false;

  WebViewController buildController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            if (!_pageLoaded.isCompleted) {
              _isLoaded = true;
              _pageLoaded.complete();
            }
          },
          onWebResourceError: (error) {
            if (!_pageLoaded.isCompleted) {
              _pageLoaded.completeError(error);
            }
          },
        ),
      );
    return _controller;
  }

  Future<void> visit(String url) async {
    _isLoaded = false;
    _pageLoaded = Completer<void>();
    await _controller.loadRequest(Uri.parse(url));
    return _pageLoaded.future;
  }

  Future<dynamic> jsInject(String script) async {
    return _controller.runJavaScriptReturningResult(script);
  }

  Future<String> getHTML() async {
    await _pageLoaded.future;
    var result = await _controller.runJavaScriptReturningResult(
      "document.documentElement.outerHTML",
    );

    return result.toString();
  }
}
