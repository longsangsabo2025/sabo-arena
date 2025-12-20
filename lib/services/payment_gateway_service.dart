import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../config/payment_config.dart';
import '../core/error_handling/standardized_error_handler.dart';
// ELON_MODE_AUTO_FIX

/// Payment Gateway Service
/// Integrates with MoMo, ZaloPay, VNPay for automatic payments
class PaymentGatewayService {
  static final PaymentGatewayService _instance =
      PaymentGatewayService._internal();
  static PaymentGatewayService get instance => _instance;
  PaymentGatewayService._internal();

  // ==================== MoMo Integration ====================

  /// Create MoMo payment
  /// Docs: https://developers.momo.vn/
  Future<Map<String, dynamic>> createMoMoPayment({
    required String partnerCode,
    required String accessKey,
    required String secretKey,
    required String orderId,
    required double amount,
    required String orderInfo,
    required String returnUrl,
    required String notifyUrl,
    String? extraData,
  }) async {
    try {
      final requestId = orderId;
      final requestType = 'captureWallet';
      final amountStr = amount.toInt().toString();

      // Create signature
      final rawSignature = 'accessKey=$accessKey'
          '&amount=$amountStr'
          '&extraData=${extraData ?? ""}'
          '&ipnUrl=$notifyUrl'
          '&orderId=$orderId'
          '&orderInfo=$orderInfo'
          '&partnerCode=$partnerCode'
          '&redirectUrl=$returnUrl'
          '&requestId=$requestId'
          '&requestType=$requestType';

      final signature = _generateHmacSHA256(rawSignature, secretKey);

      // Request body
      final body = {
        'partnerCode': partnerCode,
        'accessKey': accessKey,
        'requestId': requestId,
        'amount': amountStr,
        'orderId': orderId,
        'orderInfo': orderInfo,
        'redirectUrl': returnUrl,
        'ipnUrl': notifyUrl,
        'extraData': extraData ?? '',
        'requestType': requestType,
        'signature': signature,
        'lang': 'vi',
      };

      // API call (auto-select endpoint based on environment)
      final response = await http.post(
        Uri.parse(PaymentConfig.momoApiEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          'success': data['resultCode'] == 0,
          'payUrl': data['payUrl'],
          'deeplink': data['deeplink'],
          'qrCodeUrl': data['qrCodeUrl'],
          'message': data['message'],
          'resultCode': data['resultCode'],
        };
      } else {
        throw 'MoMo API error: ${response.statusCode}';
      }
    } catch (e) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.api,
          operation: 'createMoMoPayment',
          context: 'Failed to create MoMo payment',
        ),
      );
      rethrow;
    }
  }

  /// Verify MoMo callback
  bool verifyMoMoCallback({
    required Map<String, dynamic> callbackData,
    required String secretKey,
  }) {
    try {
      final receivedSignature = callbackData['signature'] as String;

      final rawSignature = 'accessKey=${callbackData['accessKey']}'
          '&amount=${callbackData['amount']}'
          '&extraData=${callbackData['extraData']}'
          '&message=${callbackData['message']}'
          '&orderId=${callbackData['orderId']}'
          '&orderInfo=${callbackData['orderInfo']}'
          '&orderType=${callbackData['orderType']}'
          '&partnerCode=${callbackData['partnerCode']}'
          '&payType=${callbackData['payType']}'
          '&requestId=${callbackData['requestId']}'
          '&responseTime=${callbackData['responseTime']}'
          '&resultCode=${callbackData['resultCode']}'
          '&transId=${callbackData['transId']}';

      final expectedSignature = _generateHmacSHA256(rawSignature, secretKey);

      return receivedSignature == expectedSignature;
    } catch (e) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.validation,
          operation: 'verifyMoMoCallback',
          context: 'Failed to verify MoMo callback',
        ),
      );
      return false;
    }
  }

  // ==================== ZaloPay Integration ====================

  /// Create ZaloPay payment
  /// Docs: https://docs.zalopay.vn/
  Future<Map<String, dynamic>> createZaloPayPayment({
    required String appId,
    required String key1,
    required String key2,
    required String orderId,
    required double amount,
    required String description,
    required String callbackUrl,
    String? embedData,
  }) async {
    try {
      final appTransId = '${DateTime.now().format('yyMMdd')}_$orderId';
      final appTime = DateTime.now().millisecondsSinceEpoch.toString();
      final amountStr = amount.toInt().toString();

      // Create MAC
      final macData =
          '$appId|$appTransId|$appTime|$amountStr|${embedData ?? ""}|';
      final mac = _generateHmacSHA256(macData, key1);

      // Request body
      final body = {
        'app_id': appId,
        'app_trans_id': appTransId,
        'app_user': 'user_${DateTime.now().millisecondsSinceEpoch}',
        'app_time': appTime,
        'amount': amountStr,
        'item': jsonEncode([]),
        'embed_data': embedData ?? '{}',
        'description': description,
        'bank_code': 'zalopayapp',
        'callback_url': callbackUrl,
        'mac': mac,
      };

      // API call
      final response = await http.post(
        Uri.parse('https://sb-openapi.zalopay.vn/v2/create'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['return_code'] == 1,
          'orderUrl': data['order_url'],
          'zpTransToken': data['zp_trans_token'],
          'orderToken': data['order_token'],
          'message': data['return_message'],
        };
      } else {
        throw 'ZaloPay API error: ${response.statusCode}';
      }
    } catch (e) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.api,
          operation: 'createZaloPayPayment',
          context: 'Failed to create ZaloPay payment',
        ),
      );
      rethrow;
    }
  }

  /// Verify ZaloPay callback
  bool verifyZaloPayCallback({
    required Map<String, dynamic> callbackData,
    required String key2,
  }) {
    try {
      final receivedMac = callbackData['mac'] as String;
      final dataStr = callbackData['data'] as String;

      final expectedMac = _generateHmacSHA256(dataStr, key2);

      return receivedMac == expectedMac;
    } catch (e) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.validation,
          operation: 'verifyZaloPayCallback',
          context: 'Failed to verify ZaloPay callback',
        ),
      );
      return false;
    }
  }

  // ==================== VNPay Integration ====================

  /// Create VNPay payment
  /// Docs: https://sandbox.vnpayment.vn/apis/
  Future<String> createVNPayPaymentUrl({
    required String tmnCode,
    required String hashSecret,
    required String orderId,
    required double amount,
    required String orderInfo,
    required String returnUrl,
    String? ipAddress,
  }) async {
    try {
      final vnpUrl = 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';
      final createDate = DateTime.now().format('yyyyMMddHHmmss');
      final amountStr = (amount * 100).toInt().toString(); // VNPay uses cents

      // Build params
      final params = <String, String>{
        'vnp_Version': '2.1.0',
        'vnp_Command': 'pay',
        'vnp_TmnCode': tmnCode,
        'vnp_Amount': amountStr,
        'vnp_CreateDate': createDate,
        'vnp_CurrCode': 'VND',
        'vnp_IpAddr': ipAddress ?? '127.0.0.1',
        'vnp_Locale': 'vn',
        'vnp_OrderInfo': orderInfo,
        'vnp_OrderType': 'other',
        'vnp_ReturnUrl': returnUrl,
        'vnp_TxnRef': orderId,
      };

      // Sort params
      final sortedParams = Map.fromEntries(
        params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );

      // Create hash data
      final hashData = sortedParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      // Create secure hash
      final secureHash = _generateHmacSHA512(hashData, hashSecret);

      // Build final URL
      final paymentUrl = '$vnpUrl?$hashData&vnp_SecureHash=$secureHash';

      return paymentUrl;
    } catch (e) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.api,
          operation: 'createVNPayPayment',
          context: 'Failed to create VNPay payment',
        ),
      );
      rethrow;
    }
  }

  /// Verify VNPay callback
  bool verifyVNPayCallback({
    required Map<String, String> callbackParams,
    required String hashSecret,
  }) {
    try {
      final receivedHash = callbackParams['vnp_SecureHash'];
      if (receivedHash == null) return false;

      // Remove hash from params
      final params = Map<String, String>.from(callbackParams);
      params.remove('vnp_SecureHash');
      params.remove('vnp_SecureHashType');

      // Sort params
      final sortedParams = Map.fromEntries(
        params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );

      // Create hash data
      final hashData = sortedParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      // Calculate expected hash
      final expectedHash = _generateHmacSHA512(hashData, hashSecret);

      return receivedHash == expectedHash;
    } catch (e) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.validation,
          operation: 'verifyVNPayCallback',
          context: 'Failed to verify VNPay callback',
        ),
      );
      return false;
    }
  }

  // ==================== Helper Methods ====================

  String _generateHmacSHA256(String data, String key) {
    final keyBytes = utf8.encode(key);
    final dataBytes = utf8.encode(data);
    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(dataBytes);
    return digest.toString();
  }

  String _generateHmacSHA512(String data, String key) {
    final keyBytes = utf8.encode(key);
    final dataBytes = utf8.encode(data);
    final hmac = Hmac(sha512, keyBytes);
    final digest = hmac.convert(dataBytes);
    return digest.toString();
  }
}

// Extension for date formatting
extension DateTimeFormat on DateTime {
  String format(String pattern) {
    final year = this.year.toString();
    final month = this.month.toString().padLeft(2, '0');
    final day = this.day.toString().padLeft(2, '0');
    final hour = this.hour.toString().padLeft(2, '0');
    final minute = this.minute.toString().padLeft(2, '0');
    final second = this.second.toString().padLeft(2, '0');

    return pattern
        .replaceAll('yyyy', year)
        .replaceAll('yy', year.substring(2))
        .replaceAll('MM', month)
        .replaceAll('dd', day)
        .replaceAll('HH', hour)
        .replaceAll('mm', minute)
        .replaceAll('ss', second);
  }
}
