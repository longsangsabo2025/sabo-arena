import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../core/design_system/app_colors.dart';

/// Custom YouTube Player Widget with App Branding
///
/// Features:
/// - Hides YouTube logo and branding
/// - Custom app theme colors
/// - Disable context menu (prevent "Open in YouTube")
/// - Full control over player UI
/// - User thinks it's native app video player!

class CustomVideoPlayer extends StatefulWidget {
  final String videoId;
  final bool autoPlay;
  final bool showControls;
  final Color? accentColor;
  final VoidCallback? onVideoEnded;

  const CustomVideoPlayer({
    Key? key,
    required this.videoId,
    this.autoPlay = false,
    this.showControls = true,
    this.accentColor,
    this.onVideoEnded,
  }) : super(key: key);

  @override
  State<CustomVideoPlayer> createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<CustomVideoPlayer> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: YoutubePlayerFlags(
        autoPlay: widget.autoPlay,
        mute: false,

        // IMPORTANT: These flags hide YouTube branding
        hideThumbnail: true,
        hideControls: false,
        controlsVisibleAtStart: widget.showControls,

        // Disable annotations and related videos
        disableDragSeek: false,
        enableCaption: false,

        // Loop video (optional)
        loop: false,

        // Show fullscreen button
        isLive: false,
        forceHD: false,

        // Use HTTPS for secure loading
        useHybridComposition: true,
      ),
    )..addListener(_listener);
  }

  void _listener() {
    if (_isPlayerReady && mounted && !_controller.value.isFullScreen) {
      setState(() {});
    }

    // Callback when video ends
    if (_controller.value.playerState == PlayerState.ended) {
      widget.onVideoEnded?.call();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: YoutubePlayerBuilder(
          onEnterFullScreen: () {
            // Optional: Custom fullscreen behavior
          },
          onExitFullScreen: () {
            // Optional: Custom exit fullscreen behavior
          },
          player: YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
            progressIndicatorColor: widget.accentColor ?? AppColors.primary,
            progressColors: ProgressBarColors(
              playedColor: widget.accentColor ?? AppColors.primary,
              handleColor: widget.accentColor ?? AppColors.primary,
              backgroundColor: Colors.grey.withValues(alpha: 0.3),
              bufferedColor: Colors.grey.withValues(alpha: 0.5),
            ),
            topActions: [
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _controller.metadata.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
            bottomActions: [
              CurrentPosition(),
              const SizedBox(width: 10),
              ProgressBar(
                isExpanded: true,
                colors: ProgressBarColors(
                  playedColor: widget.accentColor ?? AppColors.primary,
                  handleColor: widget.accentColor ?? AppColors.primary,
                  backgroundColor: Colors.grey.withValues(alpha: 0.3),
                  bufferedColor: Colors.grey.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 10),
              RemainingDuration(),
              const FullScreenButton(),
            ],
            onReady: () {
              setState(() {
                _isPlayerReady = true;
              });
            },
          ),
          builder: (context, player) {
            return Column(
              children: [
                // Video player
                player,

                // Optional: Custom controls overlay
                if (widget.showControls && !_controller.value.isFullScreen)
                  _buildCustomControls(),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Custom controls overlay (optional)
  Widget _buildCustomControls() {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Play/Pause button
          IconButton(
            icon: Icon(
              _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _controller.value.isPlaying
                    ? _controller.pause()
                    : _controller.play();
              });
            },
          ),

          // Volume control (optional)
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _controller.value.volume > 0
                      ? Icons.volume_up
                      : Icons.volume_off,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _controller.value.volume > 0
                        ? _controller.setVolume(0)
                        : _controller.setVolume(100);
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Video Thumbnail Widget with Play Button Overlay
/// Shows thumbnail before video is played
class VideoThumbnailWidget extends StatelessWidget {
  final String videoId;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const VideoThumbnailWidget({
    Key? key,
    required this.videoId,
    this.onTap,
    this.width,
    this.height,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // YouTube thumbnail URL (high quality)
    final thumbnailUrl = 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          color: Colors.black,
        ),
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail image
              Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[900],
                    child: const Icon(
                      Icons.video_library,
                      color: Colors.white54,
                      size: 48,
                    ),
                  );
                },
              ),

              // Play button overlay
              Container(
                color: Colors.black38,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fullscreen Video Player Dialog
/// Opens video in fullscreen overlay
class VideoPlayerDialog extends StatelessWidget {
  final String videoId;
  final bool autoPlay;

  const VideoPlayerDialog({
    Key? key,
    required this.videoId,
    this.autoPlay = true,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required String videoId,
    bool autoPlay = true,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (context) =>
          VideoPlayerDialog(videoId: videoId, autoPlay: autoPlay),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Video player (fullscreen)
          Center(
            child: CustomVideoPlayer(
              videoId: videoId,
              autoPlay: autoPlay,
              showControls: true,
            ),
          ),

          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 24),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
