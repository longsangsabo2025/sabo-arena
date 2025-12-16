import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';

/// 🎨 Shareable Tournament Card for Social Media
/// Optimized for Instagram Stories (1080x1920) and posts
class ShareableTournamentCard extends StatelessWidget {
  final String tournamentId;
  final String tournamentName;
  final String? startDate; // ISO string or formatted
  final int? participants;
  final String? prizePool;
  final String? format; // "single_elimination", "round_robin", etc.
  final String? status; // "upcoming", "ongoing", "completed"

  const ShareableTournamentCard({
    Key? key,
    required this.tournamentId,
    required this.tournamentName,
    this.startDate,
    this.participants,
    this.prizePool,
    this.format,
    this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1080,
      height: 1920,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF00695C), // Teal 700
            const Color(0xFF00897B), // Teal 500
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
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
                    '⚔️',
                    style: const TextStyle(fontSize: 100),
                  ),
                ),
              ),
              
              const SizedBox(height: 60),

              // Tournament Name
              Text(
                tournamentName,
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 40),

              // Status Badge
              if (status != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status!),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    _getStatusText(status!),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

              const SizedBox(height: 80),

              // Stats Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (startDate != null)
                    _buildStat('📅', _formatDate(startDate!)),
                  if (participants != null)
                    _buildStat('👥', '$participants'),
                  if (format != null)
                    _buildStat('🏆', _formatTournamentType(format!)),
                ],
              ),

              if (prizePool != null) ...[
                const SizedBox(height: 60),
                _buildPrizePool(prizePool!),
              ],

              const Spacer(),

              // QR Code
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: 'https://saboarena.com/tournament/$tournamentId',
                  size: 240,
                  backgroundColor: Colors.white,
                  version: QrVersions.auto,
                ),
              ),

              const SizedBox(height: 40),

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
                'Nơi Chiến Binh Hội Tụ 🎮',
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

  Widget _buildStat(String icon, String value) {
    return Column(
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 64),
        ),
        const SizedBox(height: 16),
        Text(
          value,
          style: const TextStyle(
            fontSize: 32,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPrizePool(String prize) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 60,
        vertical: 30,
      ),
      decoration: BoxDecoration(
        color: Colors.amber.shade600,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '💰 GIẢI THƯỞNG',
            style: TextStyle(
              fontSize: 28,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            prize,
            style: const TextStyle(
              fontSize: 48,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return Colors.blue.shade600;
      case 'ongoing':
        return Colors.green.shade600;
      case 'completed':
        return Colors.grey.shade600;
      default:
        return Colors.teal.shade600;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return 'SẮP DIỄN RA';
      case 'ongoing':
        return 'ĐANG DIỄN RA';
      case 'completed':
        return 'ĐÃ KẾT THÚC';
      default:
        return status.toUpperCase();
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr; // Return original if parsing fails
    }
  }

  String _formatTournamentType(String format) {
    switch (format.toLowerCase()) {
      case 'single_elimination':
        return 'Loại Trực Tiếp';
      case 'double_elimination':
        return 'Thua 2';
      case 'round_robin':
        return 'Vòng Tròn';
      case 'swiss':
        return 'Swiss';
      default:
        return format;
    }
  }
}
