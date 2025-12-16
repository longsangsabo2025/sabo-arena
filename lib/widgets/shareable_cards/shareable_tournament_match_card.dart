import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';
import '../user/user_widgets.dart';

/// Shareable Match Card for Tournament Auto-Post
/// Optimized for 4:5 ratio (Instagram/Facebook)
/// For semifinals and finals only
class ShareableMatchCard extends StatelessWidget {
  final String tournamentName;
  final String player1Name;
  final String? player1Avatar;
  final String player2Name;
  final String? player2Avatar;
  final int? player1Score;
  final int? player2Score;
  final String matchType; // 'semifinal', 'final'
  final String matchDate;
  final bool isLive;
  final String? clubName;

  const ShareableMatchCard({
    super.key,
    required this.tournamentName,
    required this.player1Name,
    this.player1Avatar,
    required this.player2Name,
    this.player2Avatar,
    this.player1Score,
    this.player2Score,
    required this.matchType,
    required this.matchDate,
    this.isLive = false,
    this.clubName,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 5, // 4:5 ratio for social media
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getGradientColors(),
          ),
        ),
        child: Stack(
          children: [
            // Background Pattern
            _buildBackgroundPattern(),
            
            // Content
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
              child: Column(
                children: [
                  // Header
                  _buildHeader(),
                  
                  SizedBox(height: 3.h),
                  
                  // Match Type Badge
                  _buildMatchTypeBadge(),
                  
                  SizedBox(height: 3.h),
                  
                  // Players VS
                  _buildPlayersSection(),
                  
                  SizedBox(height: 3.h),
                  
                  // Score or Status
                  if (player1Score != null && player2Score != null)
                    _buildScoreSection()
                  else if (isLive)
                    _buildLiveIndicator()
                  else
                    _buildUpcomingStatus(),
                  
                  const Spacer(),
                  
                  // Footer
                  _buildFooter(),
                ],
              ),
            ),
            
            // Live Badge
            if (isLive) _buildLiveBadge(),
          ],
        ),
      ),
    );
  }

  List<Color> _getGradientColors() {
    switch (matchType) {
      case 'final':
        return [
          const Color(0xFFFFD700), // Gold
          const Color(0xFFFFA500), // Orange
          const Color(0xFFFF6347), // Tomato
        ];
      case 'semifinal':
        return [
          AppTheme.primaryLight,
          AppTheme.primaryLight.withValues(alpha: 0.8),
          AppTheme.accentLight,
        ];
      default:
        return [
          Colors.blue,
          Colors.blue.withValues(alpha: 0.8),
          Colors.cyan,
        ];
    }
  }

  Widget _buildBackgroundPattern() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.1,
        child: CustomPaint(
          painter: _PatternPainter(),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
              ),
            ],
          ),
          child: Icon(
            Icons.sports_tennis,
            color: _getGradientColors()[0],
            size: 32,
          ),
        ),
        const SizedBox(height: 12),
        // Tournament Name
        Text(
          tournamentName,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (clubName != null) ...[
          const SizedBox(height: 6),
          Text(
            clubName!,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white70,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMatchTypeBadge() {
    String label;
    IconData icon;
    
    switch (matchType) {
      case 'final':
        label = 'CHUNG KẾT';
        icon = Icons.emoji_events;
        break;
      case 'semifinal':
        label = 'BÁN KẾT';
        icon = Icons.military_tech;
        break;
      default:
        label = 'TRẬN ĐẤU';
        icon = Icons.sports;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _getGradientColors()[0], size: 24),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: _getGradientColors()[0],
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersSection() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          // Player 1
          _buildPlayerInfo(
            name: player1Name,
            avatar: player1Avatar,
            isTop: true,
          ),
          
          // VS Divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 2,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white,
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'VS',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 3,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 2,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Player 2
          _buildPlayerInfo(
            name: player2Name,
            avatar: player2Avatar,
            isTop: false,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerInfo({
    required String name,
    String? avatar,
    required bool isTop,
  }) {
    return Row(
      children: [
        // Avatar
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: UserAvatarWidget(
            avatarUrl: avatar,
            size: 70,
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Name
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreSection() {
    final hasWinner = player1Score != player2Score;
    final player1Won = (player1Score ?? 0) > (player2Score ?? 0);
    
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'KẾT QUẢ',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Player 1 Score
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: player1Won && hasWinner
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: player1Won && hasWinner
                        ? Colors.green
                        : Colors.grey,
                    width: 2,
                  ),
                ),
                child: Text(
                  '${player1Score ?? 0}',
                  style: TextStyle(
                    fontSize: 36.sp,
                    fontWeight: FontWeight.bold,
                    color: player1Won && hasWinner
                        ? Colors.green
                        : Colors.grey[800],
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '-',
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              
              // Player 2 Score
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: !player1Won && hasWinner
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: !player1Won && hasWinner
                        ? Colors.green
                        : Colors.grey,
                    width: 2,
                  ),
                ),
                child: Text(
                  '${player2Score ?? 0}',
                  style: TextStyle(
                    fontSize: 36.sp,
                    fontWeight: FontWeight.bold,
                    color: !player1Won && hasWinner
                        ? Colors.green
                        : Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'ĐANG DIỄN RA',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.schedule,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            matchDate,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '🏸 Theo dõi giải đấu trên SABO ARENA',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: _getGradientColors()[0],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.download, color: Colors.grey[600], size: 18),
              const SizedBox(width: 6),
              Text(
                'saboarena.com/download',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveBadge() {
    return Positioned(
      top: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'LIVE',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom Painter for Background Pattern
class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw diagonal lines
    for (double i = -size.height; i < size.width; i += 30) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
