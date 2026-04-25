import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FileViewerPage extends StatelessWidget {
  final String url;

  const FileViewerPage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("عرض الملف")),
      body: WebViewWidget(
        controller: WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse(url)),
      ),
    );
  }
}