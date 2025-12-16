import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// 🏆 Shareable Leaderboard Card for Social Media
/// Shows Top 3 winners with podium style
class ShareableLeaderboardCard extends StatelessWidget {
  final String leaderboardId;
  final String leaderboardTitle;
  final String? subtitle; // Tournament name or period
  final String rank1Name;
  final String rank1Avatar;
  final String rank1Stats; // "1250 ELO" or "28-5 W-L"
  final String rank2Name;
  final String rank2Avatar;
  final String rank2Stats;
  final String rank3Name;
  final String rank3Avatar;
  final String rank3Stats;
  final String? dateRange;

  const ShareableLeaderboardCard({
    Key? key,
    required this.leaderboardId,
    required this.leaderboardTitle,
    this.subtitle,
    required this.rank1Name,
    required this.rank1Avatar,
    required this.rank1Stats,
    required this.rank2Name,
    required this.rank2Avatar,
    required this.rank2Stats,
    required this.rank3Name,
    required this.rank3Avatar,
    required this.rank3Stats,
    this.dateRange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1080,
      height: 1920,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6A1B9A), // Purple
            Color(0xFF8E24AA), // Light Purple
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(60),
          child: Column(
            children: [
              // Trophy Icon & Title
              const Text('🏆', style: TextStyle(fontSize: 120)),
              const SizedBox(height: 30),

              Text(
                leaderboardTitle,
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              if (subtitle != null) ...[
                const SizedBox(height: 20),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 32,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              if (dateRange != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    '📅 $dateRange',
                    style: const TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 80),

              // Podium with Top 3
              Expanded(
                child: _buildPodium(),
              ),

              const SizedBox(height: 60),

              // QR Code
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: QrImageView(
                  data: 'https://saboarena.com/leaderboard/$leaderboardId',
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: 30),

              // Domain
              const Text(
                'saboarena.com',
                style: TextStyle(
                  fontSize: 36,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 20),

              // Tagline
              Text(
                'Top Players 🎮',
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPodium() {
    return Stack(
      children: [
        // Podium bases
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Rank 2 (Left - Silver)
              _buildPodiumBase(
                height: 280,
                color: const Color(0xFFC0C0C0),
                rank: 2,
                width: 250,
              ),

              const SizedBox(width: 30),

              // Rank 1 (Center - Gold)
              _buildPodiumBase(
                height: 350,
                color: const Color(0xFFFFD700),
                rank: 1,
                width: 280,
              ),

              const SizedBox(width: 30),

              // Rank 3 (Right - Bronze)
              _buildPodiumBase(
                height: 220,
                color: const Color(0xFFCD7F32),
                rank: 3,
                width: 250,
              ),
            ],
          ),
        ),

        // Players on podium
        Positioned.fill(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Rank 2 Player
              _buildPodiumPlayer(
                name: rank2Name,
                avatar: rank2Avatar,
                stats: rank2Stats,
                rank: 2,
                bottomPadding: 290,
              ),

              const SizedBox(width: 30),

              // Rank 1 Player
              _buildPodiumPlayer(
                name: rank1Name,
                avatar: rank1Avatar,
                stats: rank1Stats,
                rank: 1,
                bottomPadding: 360,
              ),

              const SizedBox(width: 30),

              // Rank 3 Player
              _buildPodiumPlayer(
                name: rank3Name,
                avatar: rank3Avatar,
                stats: rank3Stats,
                rank: 3,
                bottomPadding: 230,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPodiumBase({
    required double height,
    required Color color,
    required int rank,
    required double width,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color,
            color.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Text(
          rank.toString(),
          style: TextStyle(
            fontSize: 120,
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumPlayer({
    required String name,
    required String avatar,
    required String stats,
    required int rank,
    required double bottomPadding,
  }) {
    // Medal emoji based on rank
    final medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : '🥉';
    final avatarSize = rank == 1 ? 180.0 : 140.0;

    return Container(
      width: rank == 1 ? 280 : 250,
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Medal
          Text(
            medal,
            style: const TextStyle(fontSize: 60),
          ),

          const SizedBox(height: 20),

          // Avatar
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: rank == 1
                    ? const Color(0xFFFFD700)
                    : rank == 2
                        ? const Color(0xFFC0C0C0)
                        : const Color(0xFFCD7F32),
                width: 6,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.network(
                avatar,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: avatarSize * 0.6,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Name
          Text(
            name,
            style: TextStyle(
              fontSize: rank == 1 ? 32 : 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 10),

          // Stats
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              stats,
              style: TextStyle(
                fontSize: rank == 1 ? 24 : 20,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
