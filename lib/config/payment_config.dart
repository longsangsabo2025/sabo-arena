/// Payment Gateway Configuration
/// Store API keys and endpoints for MoMo, ZaloPay, VNPay
class PaymentConfig {
  // ==================== MoMo Configuration ====================

  /// MoMo Environment: 'test' or 'production'
  static const String momoEnvironment =
      'test'; // Using TEST for safe development

  // PRODUCTION Credentials
  /// MoMo Partner Code (Production)
  static const String momoPartnerCode = 'MOMOQFX620240305';

  /// MoMo Access Key (Production)
  static const String momoAccessKey = '0ZeVhKpTUu2Jgnap';

  /// MoMo Secret Key (Production)
  static const String momoSecretKey = 'IQrXZ15zOzPCzrUqCbqbuyr9vl0v0K9R';

  // TEST Credentials (From MoMo Test Environment)
  /// MoMo Partner Code (Test)
  static const String momoPartnerCodeTest = 'MOMOQFX620240305_TEST';

  /// MoMo Access Key (Test)
  static const String momoAccessKeyTest = 'MDhO9mtxdHzSJUxO';

  /// MoMo Secret Key (Test)
  static const String momoSecretKeyTest = 'bXQlQGjXFgTuDb0eTKRKWfKoUgLlhSiz';

  /// Get current Partner Code based on environment
  static String get currentPartnerCode =>
      momoEnvironment == 'test' ? momoPartnerCodeTest : momoPartnerCode;

  /// Get current Access Key based on environment
  static String get currentAccessKey =>
      momoEnvironment == 'test' ? momoAccessKeyTest : momoAccessKey;

  /// Get current Secret Key based on environment
  static String get currentSecretKey =>
      momoEnvironment == 'test' ? momoSecretKeyTest : momoSecretKey;

  /// MoMo API Endpoint (auto-select based on environment)
  static String get momoApiEndpoint => momoEnvironment == 'test'
      ? 'https://test-payment.momo.vn/v2/gateway/api/create'
      : 'https://payment.momo.vn/v2/gateway/api/create';

  /// MoMo POS Endpoint
  static const String momoPosEndpoint =
      'https://payment.momo.vn/v2/gateway/api/pos';

  /// MoMo Public Key (for POS)
  static const String momoPublicKey =
      'MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAinym60dFrpXdOSB+jUKQJnFSKM8BbontImFx0MrEtebWTur6vkyZ2QMpuhDuW3MeEbjPnwQ0+/EbsR0pj8n3ZjhT3A0DnnudMEX0kgJQe0AkPR0oDKc4PVIql01GuluuZiQ4/IJrjVUtH3myUVvTpIASHUDyHRxS6FZosraMHeuHc/+p2tUUKncSbgE2UhUR7C02ZHmS2Iu8Qsn49ppSQzWvsr/Im9draasTGM/eSxeFs//9HIW7MsutRR9wQtSh7LPJ6D1b7giYppQYw6/sy+/n4gCXwZBUIROjxKaKa4VALTU/SeSdf6GwMvpAWz5nxoBJAlqZ2o3Y5R4+WlxOUQrmvQjV4JyF2Urjsw/nDw2WRn8rLiuHGcUgjmoYoar1gMNwS8igiUlGdXlTE7hAnQKU5gj1VtfPD6sijNSlYi8tWP/hDDd8wygU8EMQOV8zptCr+D6zR0l3kfVMC8v9srau6+b3edzrkfcV2zb71uo1f+X6IsnFnwTKUzYJNMM0xrcg4R6K/5dmEpSl8orjrIHDb8l/a1+mI5+eqxGShrgJ5SKux/gQsQmKbrB7U6T3pcgpmH2eajyQFxNovbhEpCQHxpbjoQ4lyYETw058q2ffi+r3G+7opzie/jNZ7i8SglfzjxmzWAyMA3FULuG2QwlQ2astbZ2DnfNACMuK3+0CAwEAAQ==';

  // ==================== Callback URLs ====================

  /// MoMo Return URL (after payment)
  static const String momoReturnUrl = 'saboarena://payment/momo/return';

  /// MoMo Notify URL (webhook) - Supabase Edge Function
  static const String momoNotifyUrl =
      'https://mogjjvscxjwvhtpkrlqr.supabase.co/functions/v1/momo-webhook';

  // ==================== ZaloPay Configuration (Optional) ====================

  /// ZaloPay App ID
  static const String? zaloPayAppId = null; // Set when available

  /// ZaloPay Key 1
  static const String? zaloPayKey1 = null;

  /// ZaloPay Key 2
  static const String? zaloPayKey2 = null;

  /// ZaloPay API Endpoint
  static const String zaloPayApiEndpoint =
      'https://sb-openapi.zalopay.vn/v2/create';

  /// ZaloPay Callback URL
  static const String zaloPayCallbackUrl =
      'https://api.saboarena.com/payment/zalopay/callback';

  // ==================== VNPay Configuration (Optional) ====================

  /// VNPay TMN Code
  static const String? vnPayTmnCode = null; // Set when available

  /// VNPay Hash Secret
  static const String? vnPayHashSecret = null;

  /// VNPay API URL
  static const String vnPayApiUrl =
      'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';

  /// VNPay Return URL
  static const String vnPayReturnUrl = 'saboarena://payment/vnpay/return';

  // ==================== Helper Methods ====================

  /// Check if MoMo is configured
  static bool get isMoMoConfigured =>
      momoPartnerCode.isNotEmpty &&
      momoAccessKey.isNotEmpty &&
      momoSecretKey.isNotEmpty;

  /// Check if ZaloPay is configured
  static bool get isZaloPayConfigured =>
      zaloPayAppId != null && zaloPayKey1 != null && zaloPayKey2 != null;

  /// Check if VNPay is configured
  static bool get isVNPayConfigured =>
      vnPayTmnCode != null && vnPayHashSecret != null;

  /// Get available payment gateways
  static List<String> get availableGateways {
    final gateways = <String>[];
    if (isMoMoConfigured) gateways.add('MoMo');
    if (isZaloPayConfigured) gateways.add('ZaloPay');
    if (isVNPayConfigured) gateways.add('VNPay');
    return gateways;
  }
}
