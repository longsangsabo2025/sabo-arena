import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class FullTournamentIframeView extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;

  const FullTournamentIframeView({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  @override
  State<FullTournamentIframeView> createState() =>
      _FullTournamentIframeViewState();
}

class _FullTournamentIframeViewState extends State<FullTournamentIframeView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;
  String? _debugUrl;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _setLandscapeOrientation();
  }

  void _setLandscapeOrientation() {
    // Force landscape orientation for full tournament view
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _initializeWebView() {
    // Build URL with proper format
    final url = 'https://saboarena.com/tournament/${widget.tournamentId}/full';
    _debugUrl = url;

    ProductionLogger.info('🌐 Loading Full Tournament URL: $url',
        tag: 'full_tournament_iframe_view_mobile');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F172A)) // Dark background
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            ProductionLogger.info('📄 Page started: $url',
                tag: 'full_tournament_iframe_view_mobile');
            if (mounted) {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
            }
          },
          onPageFinished: (String url) {
            ProductionLogger.info('✅ Page finished: $url',
                tag: 'full_tournament_iframe_view_mobile');
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            ProductionLogger.info('❌ WebView Error:',
                tag: 'full_tournament_iframe_view_mobile');
            ProductionLogger.info('   Type: ${error.errorType}',
                tag: 'full_tournament_iframe_view_mobile');
            ProductionLogger.info('   Code: ${error.errorCode}',
                tag: 'full_tournament_iframe_view_mobile');
            ProductionLogger.info('   Description: ${error.description}',
                tag: 'full_tournament_iframe_view_mobile');
            ProductionLogger.info('   URL: ${error.url}',
                tag: 'full_tournament_iframe_view_mobile');

            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Lỗi tải trang:\n'
                    'Code: ${error.errorCode}\n'
                    'Type: ${error.errorType}\n'
                    'Description: ${error.description}\n'
                    'URL: ${error.url ?? _debugUrl}';
              });
            }
          },
          onHttpError: (HttpResponseError error) {
            ProductionLogger.info(
                '🔴 HTTP Error: ${error.response?.statusCode}',
                tag: 'full_tournament_iframe_view_mobile');
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  @override
  void dispose() {
    // Restore portrait orientation when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(widget.tournamentName),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ProductionLogger.info('🔄 Manual reload triggered',
                  tag: 'full_tournament_iframe_view_mobile');
              _controller.reload();
            },
            tooltip: 'Tải lại',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Debug Info'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('URL: $_debugUrl'),
                      const SizedBox(height: 8),
                      Text('Tournament ID: ${widget.tournamentId}'),
                      const SizedBox(height: 8),
                      Text('Loading: $_isLoading'),
                      const SizedBox(height: 8),
                      Text('Error: ${_errorMessage ?? "None"}'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Debug Info',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_errorMessage != null)
            Container(
              color: const Color(0xFF1E293B),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Card(
                    color: Colors.red[50],
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline,
                              size: 72, color: Colors.red[700]),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.red[900],
                                fontFamily: 'monospace'),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'URL: $_debugUrl',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () {
                              ProductionLogger.info('🔄 Retry button pressed',
                                  tag: 'full_tournament_iframe_view_mobile');
                              _controller.reload();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Thử lại'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[700],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: const Color(0xAA0F172A),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Đang tải Full Tournament View...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
