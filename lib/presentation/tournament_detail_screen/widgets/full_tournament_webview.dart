import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class FullTournamentWebView extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;

  const FullTournamentWebView({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  @override
  State<FullTournamentWebView> createState() => _FullTournamentWebViewState();
}

class _FullTournamentWebViewState extends State<FullTournamentWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            ProductionLogger.info('❌ WebView error: ${error.description}', tag: 'full_tournament_webview');
          },
        ),
      )
      ..loadRequest(
        Uri.parse('http://localhost:8083/tournament/${widget.tournamentId}/full'),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tournamentName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
