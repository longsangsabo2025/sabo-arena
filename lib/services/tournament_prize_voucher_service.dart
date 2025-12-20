import '../services/supabase_service.dart';
import '../core/error_handling/standardized_error_handler.dart';
import 'package:sabo_arena/utils/production_logger.dart';

/// Service để quản lý tournament prize vouchers
class TournamentPrizeVoucherService {
  final _supabase = SupabaseService.instance.client;

  /// Setup prize vouchers cho giải đấu (Club owner)
  /// Ví dụ: Nhất = 700K, Nhì = 500K, Ba = 300K
  Future<void> setupTournamentPrizeVouchers({
    required String tournamentId,
    required List<TournamentPrizeConfig> prizes,
  }) async {
    try {
      // Xóa config cũ (nếu có)
      await _supabase
          .from('tournament_prize_vouchers')
          .delete()
          .eq('tournament_id', tournamentId);

      // Insert prize configs
      final prizeData = prizes
          .map((prize) => {
                'tournament_id': tournamentId,
                'position': prize.position,
                'position_label': prize.positionLabel,
                'voucher_value': prize.voucherValue,
                'voucher_code_prefix': prize.codePrefix,
                'voucher_description': prize.description,
                'valid_days': prize.validDays,
              })
          .toList();

      await _supabase.from('tournament_prize_vouchers').insert(prizeData);

      ProductionLogger.info(
          'Setup ${prizes.length} prize vouchers for tournament',
          tag: 'TournamentPrizeVoucher');
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'setupTournamentPrizeVouchers',
          context: 'Lỗi khi thiết lập voucher giải thưởng',
        ),
      );
      ProductionLogger.error('Lỗi khi thiết lập voucher giải thưởng',
          error: e, stackTrace: stackTrace, tag: 'TournamentPrizeVoucher');
      rethrow;
    }
  }

  /// Lấy danh sách prize vouchers của giải đấu
  Future<List<Map<String, dynamic>>> getTournamentPrizeVouchers(
    String tournamentId,
  ) async {
    try {
      final response = await _supabase
          .from('tournament_prize_vouchers')
          .select()
          .eq('tournament_id', tournamentId)
          .order('position');

      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'getTournamentPrizeVouchers',
          context: 'Lỗi khi lấy danh sách voucher giải thưởng',
        ),
      );
      ProductionLogger.error('Lỗi khi lấy danh sách voucher giải thưởng',
          error: e, stackTrace: stackTrace, tag: 'TournamentPrizeVoucher');
      rethrow;
    }
  }

  /// Lấy tất cả prize vouchers của CLB (từ tất cả giải đấu)
  Future<List<Map<String, dynamic>>> getClubPrizeVouchers(
    String clubId,
  ) async {
    try {
      final response = await _supabase
          .from('tournament_prize_vouchers')
          .select('''
            *,
            tournament:tournaments!inner(
              id,
              title,
              club_id
            )
          ''')
          .eq('tournament.club_id', clubId)
          .order('created_at', ascending: false);

      // Add tournament name to each voucher
      final vouchers = List<Map<String, dynamic>>.from(response);
      for (var voucher in vouchers) {
        final tournament = voucher['tournament'] as Map<String, dynamic>?;
        if (tournament != null) {
          voucher['tournament_name'] = tournament['title'];
        }
      }

      return vouchers;
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'getClubPrizeVouchers',
          context: 'Lỗi khi lấy danh sách voucher giải thưởng của CLB',
        ),
      );
      ProductionLogger.error(
          'Lỗi khi lấy danh sách voucher giải thưởng của CLB',
          error: e,
          stackTrace: stackTrace,
          tag: 'TournamentPrizeVoucher');
      rethrow;
    }
  }

  /// Phát voucher cho user thắng giải (tự động sau khi kết thúc tournament)
  Future<Map<String, dynamic>> issuePrizeVoucher({
    required String tournamentId,
    required String userId,
    required int position,
  }) async {
    try {
      ProductionLogger.debug(
        'BEFORE RPC CALL: tournament_id: $tournamentId, user_id: $userId, position: $position',
        tag: 'TournamentPrizeVoucher',
      );

      final response = await _supabase.rpc(
        'issue_tournament_prize_vouchers',
        params: {
          'p_tournament_id': tournamentId,
          'p_user_id': userId,
          'p_position': position,
        },
      );

      final responseInfo = response is Map
          ? 'response keys: ${(response).keys.join(", ")}'
          : 'response type: ${response.runtimeType}';
      ProductionLogger.debug('AFTER RPC CALL: $responseInfo',
          tag: 'TournamentPrizeVoucher');

      ProductionLogger.info(
        'Issued prize voucher for position $position - Voucher code: ${response['voucher_code']}, Value: ${response['voucher_value']} VND',
        tag: 'TournamentPrizeVoucher',
      );

      return Map<String, dynamic>.from(response);
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'issuePrizeVoucher',
          context: 'Lỗi khi cấp voucher giải thưởng',
        ),
      );
      ProductionLogger.error('Lỗi khi cấp voucher giải thưởng',
          error: e, stackTrace: stackTrace, tag: 'TournamentPrizeVoucher');
      rethrow;
    }
  }

  /// Lấy vouchers của user có thể dùng thanh toán bàn
  Future<List<Map<String, dynamic>>> getUserTablePaymentVouchers(
    String userId,
  ) async {
    try {
      final response = await _supabase
          .from('user_vouchers')
          .select('''
            *,
            tournament:tournaments(id, title, club_id)
          ''')
          .eq('user_id', userId)
          .eq('status', 'active')
          .eq('can_use_for_table_payment', true)
          .or('expires_at.is.null,expires_at.gt.${DateTime.now().toIso8601String()}')
          .order('voucher_value', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'getUserTablePaymentVouchers',
          context: 'Lỗi khi lấy danh sách voucher thanh toán bàn',
        ),
      );
      ProductionLogger.error('Lỗi khi lấy danh sách voucher thanh toán bàn',
          error: e, stackTrace: stackTrace, tag: 'TournamentPrizeVoucher');
      rethrow;
    }
  }

  /// Apply voucher để thanh toán tiền bàn
  Future<Map<String, dynamic>> applyVoucherToTablePayment({
    required String userId,
    required String clubId,
    required String voucherCode,
    required double originalAmount,
    required int tableNumber,
    required DateTime sessionStart,
    DateTime? sessionEnd,
  }) async {
    try {
      final response = await _supabase.rpc(
        'apply_voucher_to_table_payment',
        params: {
          'p_user_id': userId,
          'p_club_id': clubId,
          'p_voucher_code': voucherCode,
          'p_original_amount': originalAmount,
          'p_table_number': tableNumber,
          'p_session_start': sessionStart.toIso8601String(),
          'p_session_end': (sessionEnd ?? DateTime.now()).toIso8601String(),
        },
      );

      ProductionLogger.info(
        'Applied voucher to table payment - Original: ${response['original_amount']} VND, Discount: ${response['voucher_discount']} VND, Final: ${response['final_amount']} VND',
        tag: 'TournamentPrizeVoucher',
      );

      return Map<String, dynamic>.from(response);
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'applyVoucherToTablePayment',
          context: 'Lỗi khi áp dụng voucher',
        ),
      );
      ProductionLogger.error('Lỗi khi áp dụng voucher',
          error: e, stackTrace: stackTrace, tag: 'TournamentPrizeVoucher');
      rethrow;
    }
  }

  /// Lấy lịch sử thanh toán bàn bằng voucher của user
  Future<List<Map<String, dynamic>>> getUserTablePaymentHistory(
    String userId,
  ) async {
    try {
      final response = await _supabase
          .from('table_voucher_payments')
          .select('''
            *,
            club:clubs(id, name, image_url),
            voucher:user_vouchers(voucher_code, voucher_value, tournament_id)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'getUserTablePaymentHistory',
          context: 'Lỗi khi lấy lịch sử thanh toán',
        ),
      );
      ProductionLogger.error('Lỗi khi lấy lịch sử thanh toán',
          error: e, stackTrace: stackTrace, tag: 'TournamentPrizeVoucher');
      rethrow;
    }
  }

  /// Lấy lịch sử thanh toán bàn của club
  Future<List<Map<String, dynamic>>> getClubTablePaymentHistory(
    String clubId,
  ) async {
    try {
      final response = await _supabase
          .from('table_voucher_payments')
          .select('''
            *,
            user:users(id, full_name, avatar_url),
            voucher:user_vouchers(voucher_code, voucher_value)
          ''')
          .eq('club_id', clubId)
          .order('created_at', ascending: false)
          .limit(100);

      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'getClubTablePaymentHistory',
          context: 'Lỗi khi lấy lịch sử thanh toán của CLB',
        ),
      );
      ProductionLogger.error('Lỗi khi lấy lịch sử thanh toán của CLB',
          error: e, stackTrace: stackTrace, tag: 'TournamentPrizeVoucher');
      rethrow;
    }
  }
}

/// Config cho một giải thưởng
class TournamentPrizeConfig {
  final int position; // 1 = Nhất, 2 = Nhì, 3 = Ba
  final String positionLabel; // "NHẤT", "NHÌ", "BA"
  final double voucherValue; // 700000, 500000, 300000
  final String codePrefix; // "PRIZE", "BILLIARD"
  final String? description;
  final int validDays; // Số ngày voucher có giá trị

  TournamentPrizeConfig({
    required this.position,
    required this.positionLabel,
    required this.voucherValue,
    this.codePrefix = 'PRIZE',
    this.description,
    this.validDays = 30,
  });
}

/// Helper để tạo prize config nhanh theo poster
class PosterPrizeConfigs {
  /// Config theo poster: Total 4,500,000 VND
  /// Nhất: 1600K + 700K voucher
  /// Nhì: 700K + 500K voucher
  /// 2 giải Ba: 200K + 300K voucher mỗi người
  static List<TournamentPrizeConfig> billiardTournamentPoster() {
    return [
      TournamentPrizeConfig(
        position: 1,
        positionLabel: 'NHẤT',
        voucherValue: 700000,
        codePrefix: 'PRIZE',
        description: 'Giải Nhất - Voucher 700K thanh toán tiền bàn',
        validDays: 30,
      ),
      TournamentPrizeConfig(
        position: 2,
        positionLabel: 'NHÌ',
        voucherValue: 500000,
        codePrefix: 'PRIZE',
        description: 'Giải Nhì - Voucher 500K thanh toán tiền bàn',
        validDays: 30,
      ),
      TournamentPrizeConfig(
        position: 3,
        positionLabel: 'BA',
        voucherValue: 300000,
        codePrefix: 'PRIZE',
        description: 'Giải Ba - Voucher 300K thanh toán tiền bàn',
        validDays: 30,
      ),
      // Nếu có 2 người đứng thứ 3, phát cho cả 2
    ];
  }

  /// Config nhỏ hơn cho giải nhỏ
  static List<TournamentPrizeConfig> smallTournament() {
    return [
      TournamentPrizeConfig(
        position: 1,
        positionLabel: 'NHẤT',
        voucherValue: 200000,
        validDays: 30,
      ),
      TournamentPrizeConfig(
        position: 2,
        positionLabel: 'NHÌ',
        voucherValue: 100000,
        validDays: 30,
      ),
    ];
  }
}
