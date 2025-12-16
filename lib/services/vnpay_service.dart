import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Service tích hợp VNPay QR Code
/// Đơn giản và dễ tích hợp cho thanh toán
class VNPayService {
  // VNPay QR Code API endpoint (sandbox)
  static const String _sandboxUrl = 'https://sandbox.vnpayment.vn/qr/api';
  static const String _productionUrl = 'https://api.vnpayment.vn/qr/api';

  /// Tạo VNPay QR Code URL
  /// Phương thức này tạo QR code để khách hàng quét và thanh toán
  static String generateVNPayQRUrl({
    required String tmnCode, // Mã website/app của merchant tại VNPay
    required String amount, // Số tiền (VNĐ)
    required String orderInfo, // Thông tin đơn hàng
    required String txnRef, // Mã tham chiếu giao dịch (unique)
    required String hashSecret, // Secret key từ VNPay
    String? bankCode, // Mã ngân hàng (optional)
    bool isProduction = false,
  }) {
    final baseUrl = isProduction ? _productionUrl : _sandboxUrl;

    // Tạo timestamp
    final now = DateTime.now();
    final createDate = _formatDateTime(now);
    final expireDate = _formatDateTime(
      now.add(const Duration(minutes: 15)),
    ); // Expire sau 15p

    // Tạo parameters
    final params = <String, String>{
      'vnp_Version': '2.1.0',
      'vnp_Command': 'pay',
      'vnp_TmnCode': tmnCode,
      'vnp_Amount': (int.parse(amount) * 100).toString(), // VNPay yêu cầu *100
      'vnp_CurrCode': 'VND',
      'vnp_TxnRef': txnRef,
      'vnp_OrderInfo': orderInfo,
      'vnp_OrderType': 'other',
      'vnp_Locale': 'vn',
      'vnp_ReturnUrl': 'https://saboarena.app/payment/callback',
      'vnp_CreateDate': createDate,
      'vnp_ExpireDate': expireDate,
      'vnp_IpAddr': '127.0.0.1',
    };

    // Thêm bank code nếu có
    if (bankCode != null && bankCode.isNotEmpty) {
      params['vnp_BankCode'] = bankCode;
    }

    // Sắp xếp parameters theo alphabet
    final sortedKeys = params.keys.toList()..sort();

    // Tạo query string
    final queryString = sortedKeys
        .map((key) => '$key=${Uri.encodeComponent(params[key]!)}')
        .join('&');

    // Tạo secure hash
    final secureHash = _createSecureHash(queryString, hashSecret);

    // Tạo final URL
    final finalUrl = '$baseUrl?$queryString&vnp_SecureHash=$secureHash';

    return finalUrl;
  }

  /// Tạo VNPay QR Code data cho QR generator
  /// Trả về string để tạo QR code image
  static String generateVNPayQRData({
    required String tmnCode,
    required String amount,
    required String orderInfo,
    required String txnRef,
    required String hashSecret,
    String? bankCode,
  }) {
    // VNPay QR format (simplified)
    final qrData = {
      'provider': 'VNPAY',
      'tmnCode': tmnCode,
      'amount': amount,
      'orderInfo': orderInfo,
      'txnRef': txnRef,
      if (bankCode != null) 'bankCode': bankCode,
    };

    return json.encode(qrData);
  }

  /// Validate VNPay callback/webhook
  static bool validateCallback({
    required Map<String, String> params,
    required String hashSecret,
  }) {
    try {
      final receivedHash = params['vnp_SecureHash'];
      if (receivedHash == null) return false;

      // Remove hash from params
      final paramsWithoutHash = Map<String, String>.from(params)
        ..remove('vnp_SecureHash')
        ..remove('vnp_SecureHashType');

      // Sort and create query string
      final sortedKeys = paramsWithoutHash.keys.toList()..sort();
      final queryString = sortedKeys
          .map((key) => '$key=${Uri.encodeComponent(paramsWithoutHash[key]!)}')
          .join('&');

      // Calculate hash
      final calculatedHash = _createSecureHash(queryString, hashSecret);

      return receivedHash == calculatedHash;
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.info('Error validating VNPay callback: $e', tag: 'vnpay_service');
      }
      return false;
    }
  }

  /// Parse VNPay response
  static Map<String, dynamic> parseVNPayResponse(Map<String, String> params) {
    return {
      'success': params['vnp_ResponseCode'] == '00',
      'transactionId': params['vnp_TransactionNo'],
      'txnRef': params['vnp_TxnRef'],
      'amount': params['vnp_Amount'] != null
          ? (int.parse(params['vnp_Amount']!) / 100).toString()
          : '0',
      'orderInfo': params['vnp_OrderInfo'],
      'responseCode': params['vnp_ResponseCode'],
      'bankCode': params['vnp_BankCode'],
      'cardType': params['vnp_CardType'],
      'payDate': params['vnp_PayDate'],
    };
  }

  /// Tạo secure hash theo HMAC SHA512
  static String _createSecureHash(String data, String secretKey) {
    final key = utf8.encode(secretKey);
    final bytes = utf8.encode(data);
    final hmacSha512 = Hmac(sha512, key);
    final digest = hmacSha512.convert(bytes);
    return digest.toString();
  }

  /// Format datetime cho VNPay (yyyyMMddHHmmss)
  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}'
        '${dateTime.month.toString().padLeft(2, '0')}'
        '${dateTime.day.toString().padLeft(2, '0')}'
        '${dateTime.hour.toString().padLeft(2, '0')}'
        '${dateTime.minute.toString().padLeft(2, '0')}'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }

  /// Danh sách ngân hàng hỗ trợ VNPay
  static const Map<String, String> supportedBanks = {
    'VNPAYQR': 'Cổng thanh toán VNPAYQR',
    'VNBANK': 'Ngân hàng nội địa',
    'INTCARD': 'Thẻ quốc tế',
    'VIETCOMBANK': 'Vietcombank',
    'VIETINBANK': 'VietinBank',
    'BIDV': 'BIDV',
    'AGRIBANK': 'Agribank',
    'TECHCOMBANK': 'Techcombank',
    'ACB': 'ACB',
    'MB': 'MB Bank',
    'SACOMBANK': 'Sacombank',
    'VPBank': 'VPBank',
    'TPBank': 'TPBank',
    'HDBANK': 'HDBank',
    'SCB': 'SCB',
    'VIB': 'VIB',
    'SHB': 'SHB',
    'OCB': 'OCB',
  };

  /// Response codes của VNPay
  static const Map<String, String> responseCodes = {
    '00': 'Giao dịch thành công',
    '07': 'Trừ tiền thành công. Giao dịch bị nghi ngờ',
    '09': 'Giao dịch không thành công do thẻ chưa đăng ký dịch vụ',
    '10': 'Giao dịch không thành công do xác thực thông tin thẻ sai',
    '11': 'Giao dịch không thành công do đã hết hạn chờ thanh toán',
    '12': 'Giao dịch không thành công do thẻ bị khóa',
    '13': 'Giao dịch không thành công do sai mật khẩu xác thực',
    '24': 'Giao dịch không thành công do khách hàng hủy',
    '51': 'Giao dịch không thành công do tài khoản không đủ số dư',
    '65': 'Giao dịch không thành công do tài khoản vượt quá hạn mức',
    '75': 'Ngân hàng thanh toán đang bảo trì',
    '79': 'Giao dịch không thành công do nhập sai mật khẩu quá số lần',
    '99': 'Lỗi khác',
  };

  /// Get message from response code
  static String getResponseMessage(String code) {
    return responseCodes[code] ?? 'Lỗi không xác định';
  }

  /// Tạo test payment data (cho development)
  static Map<String, String> createTestPaymentData() {
    return {
      'tmnCode': 'TEST_TMN_CODE', // Thay bằng mã thực từ VNPay
      'hashSecret': 'TEST_HASH_SECRET', // Thay bằng secret thực từ VNPay
      'amount': '100000',
      'orderInfo': 'Thanh toan don hang test',
      'txnRef': 'TEST_${DateTime.now().millisecondsSinceEpoch}',
    };
  }

  /// Validate VNPay configuration
  static bool validateConfig({
    required String tmnCode,
    required String hashSecret,
  }) {
    if (tmnCode.isEmpty || tmnCode.length < 8) return false;
    if (hashSecret.isEmpty || hashSecret.length < 32) return false;
    return true;
  }

  /// Tạo deep link cho VNPay mobile app
  static String generateVNPayDeepLink({
    required String tmnCode,
    required String amount,
    required String orderInfo,
    required String txnRef,
    required String hashSecret,
  }) {
    final qrUrl = generateVNPayQRUrl(
      tmnCode: tmnCode,
      amount: amount,
      orderInfo: orderInfo,
      txnRef: txnRef,
      hashSecret: hashSecret,
    );

    // VNPay deep link format
    return 'vnpay://payment?url=${Uri.encodeComponent(qrUrl)}';
  }
}
