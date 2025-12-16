import 'package:flutter/material.dart';

// Web-only implementation. This file uses `dart:html` and the
// platform view registry to embed an iframe into the Flutter web page.
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;

class FullTournamentIframeView extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;

  const FullTournamentIframeView({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  @override
  State<FullTournamentIframeView> createState() => _FullTournamentIframeViewState();
}

class _FullTournamentIframeViewState extends State<FullTournamentIframeView> {
  late String _iframeId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _iframeId = 'tournament-iframe-${widget.tournamentId}-${DateTime.now().millisecondsSinceEpoch}';
    _registerIframe();
    _simulateLoading();
  }

  void _registerIframe() {
    try {
      ui_web.platformViewRegistry.registerViewFactory(
        _iframeId,
        (int viewId) {
          final iframe = html.IFrameElement()
            ..src = 'https://saboarena.com/tournament/${widget.tournamentId}/full'
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.position = 'fixed'
            ..style.top = '0'
            ..style.left = '0'
            ..style.zIndex = '9999'
            ..allow = 'fullscreen'
            ..allowFullscreen = true;

          iframe.onLoad.listen((event) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              try {
                iframe.requestFullscreen();
              } catch (e) {
                // ignore fullscreen failures
              }
            }
          });

          iframe.onError.listen((event) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Không thể tải trang. Vui lòng thử lại.';
              });
            }
          });

          return iframe;
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Lỗi: ${e.toString()}';
        });
      }
    }
  }

  void _simulateLoading() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _refresh() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _iframeId = 'tournament-iframe-${widget.tournamentId}-${DateTime.now().millisecondsSinceEpoch}';
      _registerIframe();
      _simulateLoading();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 2,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.tournamentName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Bảng đấu đầy đủ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
            tooltip: 'Làm mới',
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Đóng',
          ),
        ],
      ),
      body: Stack(
        children: [
          HtmlElementView(viewType: _iframeId),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Đang tải bảng đấu...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_errorMessage != null)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Thử lại'),
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
