import 'package:flutter/material.dart';
import '../../../services/tournament_prize_voucher_service.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class PrizePoolWidget extends StatefulWidget {
  final Map<String, dynamic> tournament;

  const PrizePoolWidget({super.key, required this.tournament});

  @override
  State<PrizePoolWidget> createState() => _PrizePoolWidgetState();
}

class _PrizePoolWidgetState extends State<PrizePoolWidget> {
  final _prizeVoucherService = TournamentPrizeVoucherService();
  List<Map<String, dynamic>> _prizeVouchers = [];

  @override
  void initState() {
    super.initState();
    _loadPrizeVouchers();
  }

  Future<void> _loadPrizeVouchers() async {
    final tournamentId = widget.tournament['id'] as String?;
    if (tournamentId == null) {
      setState(() => _loadingVouchers = false);
      return;
    }

    try {
      final vouchers = await _prizeVoucherService.getTournamentPrizeVouchers(tournamentId);
      if (mounted) {
        setState(() {
          _prizeVouchers = vouchers;
          _loadingVouchers = false;
        });
      }
    } catch (e) {
      ProductionLogger.info('Error loading prize vouchers: $e', tag: 'prize_pool_widget');
      if (mounted) {
        setState(() => _loadingVouchers = false);
      }
    }
  }

  // Format amount as string with VND suffix
  String _formatAmount(int amount) {
    if (amount >= 1000000) {
      final millions = amount / 1000000;
      if (millions == millions.toInt()) {
        return '${millions.toInt()}.000.000 VND';
      }
      return '${millions.toStringAsFixed(3).replaceAll('.', '.')}.000 VND';
    } else if (amount >= 1000) {
      final thousands = amount / 1000;
      if (thousands == thousands.toInt()) {
        return '${thousands.toInt()}.000 VND';
      }
      return '${thousands.toStringAsFixed(0)}.000 VND';
    }
    return '$amount VND';
  }

  // Get voucher info for a specific position
  Map<String, dynamic>? _getVoucherForPosition(int position) {
    try {
      return _prizeVouchers.firstWhere(
        (v) => v['position'] == position,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ NEW: Get prize distribution from tournament data
    final prizeDistribution = widget.tournament["prize_distribution"] as Map<String, dynamic>?;
    final customDistribution = prizeDistribution?['distribution'] as List?;
    
    // Build prize data from custom distribution or fallback to old prizePool
    Map<String, dynamic> prizePool;
    
    if (customDistribution != null && customDistribution.isNotEmpty) {
      // ✅ Use custom distribution (array format)
      prizePool = {
        'first': _formatAmount(customDistribution.isNotEmpty ? customDistribution[0]['cashAmount'] ?? 0 : 0),
        'second': _formatAmount(customDistribution.length > 1 ? customDistribution[1]['cashAmount'] ?? 0 : 0),
        'third': _formatAmount(customDistribution.length > 2 ? customDistribution[2]['cashAmount'] ?? 0 : 0),
        'fourth': customDistribution.length > 3 ? _formatAmount(customDistribution[3]['cashAmount'] ?? 0) : null,
      };
      ProductionLogger.info('✅ [PRIZE POOL WIDGET] Using custom distribution array: $prizePool', tag: 'prize_pool_widget');
    } else if (prizeDistribution != null && prizeDistribution.containsKey('first')) {
      // ✅ NEW: Use direct prize_distribution with text values (first, second, third keys)
      prizePool = {
        'first': prizeDistribution['first'] ?? '0 VND',
        'second': prizeDistribution['second'] ?? '0 VND',
        'third': prizeDistribution['third'] ?? '0 VND',
        'fourth': prizeDistribution['fourth'],
        'fifth_to_eighth': prizeDistribution['fifth_to_eighth'],
      };
      ProductionLogger.info('✅ [PRIZE POOL WIDGET] Using prize_distribution text: $prizePool', tag: 'prize_pool_widget');
    } else {
      // Fallback to old prizePool structure or calculate from prize_pool
      final oldPrizePool = widget.tournament["prizePool"] as Map<String, dynamic>?;
      
      if (oldPrizePool != null && oldPrizePool.containsKey('first')) {
        // Old structure has first, second, third already formatted
        prizePool = oldPrizePool;
        ProductionLogger.info('⚠️ [PRIZE POOL WIDGET] Using old prizePool structure with prizes', tag: 'prize_pool_widget');
      } else {
        // Calculate from raw prize_pool value
        final totalPrizePool = (widget.tournament["prize_pool"] as num?)?.toInt() ?? 0;
        prizePool = {
          'first': _formatAmount((totalPrizePool * 0.5).toInt()),
          'second': _formatAmount((totalPrizePool * 0.3).toInt()),
          'third': _formatAmount((totalPrizePool * 0.2).toInt()),
        };
        ProductionLogger.info('⚠️ [PRIZE POOL WIDGET] Calculating from prize_pool: $totalPrizePool', tag: 'prize_pool_widget');
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0866FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.monetization_on,
                    size: 20,
                    color: Color(0xFF0866FF),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Giải thưởng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF050505),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE4E6EB)),
          // Prize list - compact layout with voucher info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: _buildCompactPrizeList(prizePool)),
          ),
        ],
      ),
    );
  }

  // Helper to parse prize string into components
  Map<String, dynamic> _parsePrizeString(String prizeStr) {
    // Pattern: "1.000.000 VNĐ + 500k Voucher + Bảng vinh danh"
    final parts = prizeStr.split('+').map((s) => s.trim()).toList();
    
    String? cash;
    String? voucher;
    bool hasHonorBoard = false;
    
    for (final part in parts) {
      if (part.contains('VNĐ') || part.contains('VND')) {
        cash = part;
      } else if (part.toLowerCase().contains('voucher')) {
        voucher = part.replaceAll(RegExp(r'[Vv]oucher\s*:?\s*'), '').trim();
        if (voucher.isEmpty) voucher = part;
      } else if (part.toLowerCase().contains('bảng vinh danh') || part.toLowerCase().contains('vinh danh')) {
        hasHonorBoard = true;
      }
    }
    
    return {
      'cash': cash,
      'voucher': voucher,
      'hasHonorBoard': hasHonorBoard,
      'raw': prizeStr,
    };
  }

  List<Widget> _buildCompactPrizeList(Map<String, dynamic> prizePool) {
    final prizes = <Map<String, dynamic>>[
      {
        'position': '🥇',
        'label': 'Vô địch',
        'positionNum': 1,
        'prizeData': _parsePrizeString(prizePool["first"] ?? '0 VND'),
        'color': const Color(0xFFFFD700), // Gold
        'bgGradient': [const Color(0xFFFFF9E6), const Color(0xFFFFF3CC)],
      },
      {
        'position': '🥈',
        'label': 'Á quân',
        'positionNum': 2,
        'prizeData': _parsePrizeString(prizePool["second"] ?? '0 VND'),
        'color': const Color(0xFF8B8B8B), // Silver
        'bgGradient': [const Color(0xFFF8F8F8), const Color(0xFFEEEEEE)],
      },
      {
        'position': '🥉',
        'label': 'Hạng 3',
        'positionNum': 3,
        'prizeData': _parsePrizeString(prizePool["third"] ?? '0 VND'),
        'color': const Color(0xFFCD7F32), // Bronze
        'bgGradient': [const Color(0xFFFFF5EB), const Color(0xFFFFEED9)],
      },
    ];
    
    // ✅ Add 4th position if exists (for SABO DE16 with 2x 3rd place)
    if (prizePool["fourth"] != null) {
      prizes.add({
        'position': '🥉',
        'label': 'Hạng 3',
        'positionNum': 4,
        'prizeData': _parsePrizeString(prizePool["fourth"]),
        'color': const Color(0xFFCD7F32), // Bronze (same as 3rd)
        'bgGradient': [const Color(0xFFFFF5EB), const Color(0xFFFFEED9)],
      });
    }
    
    // ✅ Add Top 5-8 if exists
    if (prizePool["fifth_to_eighth"] != null) {
      prizes.add({
        'position': '🏅',
        'label': 'Top 5-8',
        'positionNum': 5,
        'prizeData': _parsePrizeString(prizePool["fifth_to_eighth"]),
        'color': const Color(0xFF4A90D9), // Blue
        'bgGradient': [const Color(0xFFEBF4FF), const Color(0xFFD6E8FF)],
      });
    }

    return prizes.asMap().entries.map((entry) {
      final prize = entry.value;
      final isLast = entry.key == prizes.length - 1;
      final prizeData = prize['prizeData'] as Map<String, dynamic>;
      final bgGradient = prize['bgGradient'] as List<Color>;
      final color = prize['color'] as Color;

      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: bgGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Medal icon
                Text(
                  prize['position'] as String,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                // Prize info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Position label
                      Text(
                        prize['label'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: color.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Cash prize (if exists)
                      if (prizeData['cash'] != null)
                        Text(
                          prizeData['cash'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                    ],
                  ),
                ),
                // Icons for voucher and honor board
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Voucher icon
                    if (prizeData['voucher'] != null)
                      Tooltip(
                        message: prizeData['voucher'] as String,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.card_giftcard,
                                size: 18,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                prizeData['voucher'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Honor board icon
                    if (prizeData['hasHonorBoard'] == true) ...[
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Bảng vinh danh',
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '📜',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (!isLast) const SizedBox(height: 10),
        ],
      );
    }).toList();
  }
}
