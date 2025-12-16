import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Service for issuing vouchers to top performers
class VoucherIssuanceService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Random _random = Random();

  /// Issue vouchers to top 4 finishers
  Future<void> issueTopPerformerVouchers({
    required String tournamentId,
    required List<Map<String, dynamic>> standings,
    required Map<String, dynamic> tournament,
  }) async {
    ProductionLogger.debug('Debug log', tag: 'AutoFix');

    // Get prize distribution config
    final prizeDistJson = tournament['prize_distribution'];
    if (prizeDistJson == null || prizeDistJson is! Map) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return;
    }

    final voucherTemplate = prizeDistJson['template'] ?? 'top_4';
    ProductionLogger.debug('Debug log', tag: 'AutoFix');

    // Get voucher configs for top 4 positions
    final voucherConfigs = await _supabase
        .from('tournament_prize_vouchers')
        .select('*')
        .eq('distribution_template', voucherTemplate)
        .lte('position', 4)
        .order('position', ascending: true);

    if (voucherConfigs.isEmpty) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return;
    }

    ProductionLogger.debug('Debug log', tag: 'AutoFix');

    // Issue vouchers to top 4
    int issuedCount = 0;
    for (final config in voucherConfigs) {
      final position = config['position'] as int;
      
      if (position > standings.length) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        continue;
      }

      final standing = standings[position - 1]; // 0-indexed
      final userId = standing['participant_id'] as String;
      final userName = standing['participant_name'] as String;

      try {
        // 🛡️ DEDUPLICATION CHECK: Prevent duplicate voucher issuance
        final existingVoucher = await _supabase
            .from('user_vouchers')
            .select('id, voucher_code')
            .eq('tournament_id', tournamentId)
            .eq('user_id', userId)
            .eq('position', position);
        
        if (existingVoucher.isNotEmpty) {
          final voucherCode = existingVoucher.first['voucher_code'];
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
          continue; // Skip duplicate
        }

        final voucherCode = _generateVoucherCode();
        final expiryDate = DateTime.now().add(Duration(days: config['expiry_days'] ?? 30));

        await _supabase.from('user_vouchers').insert({
          'user_id': userId,
          'voucher_code': voucherCode,
          'voucher_type': config['voucher_type'],
          'discount_amount': config['discount_amount'],
          'discount_percentage': config['discount_percentage'],
          'max_discount': config['max_discount'],
          'min_order_value': config['min_order_value'],
          'expires_at': expiryDate.toIso8601String(),
          'tournament_id': tournamentId,
          'position': position,
          'status': 'active',
          'issued_at': DateTime.now().toIso8601String(),
        });

        issuedCount++;
        ProductionLogger.debug('Debug log', tag: 'AutoFix');

      } catch (e) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    }

    ProductionLogger.debug('Debug log', tag: 'AutoFix');
  }

  /// Generate unique voucher code
  String _generateVoucherCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(8, (_) => chars[_random.nextInt(chars.length)]).join();
  }
}

