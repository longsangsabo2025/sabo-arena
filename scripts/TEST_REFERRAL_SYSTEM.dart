// 📋 TEST SCRIPT - Chạy trong Flutter app để kiểm tra tất cả tính năng đã triển khai

import 'package:sabo_arena/services/referral_service.dart';
import 'package:sabo_arena/services/share_service.dart';
import 'package:sabo_arena/services/deep_link_service.dart';
import 'package:sabo_arena/models/user_profile.dart';

/// Hàm test toàn bộ hệ thống referral + QR code
Future<void> runCompleteReferralSystemTest() async {
  print('🧪 Bắt đầu test toàn bộ hệ thống referral + QR code...');

  try {
    // 1. Test tạo mã ref cho users hiện có (nếu chưa có)
    print('\n📋 Test 1: Tạo mã ref cho users hiện có...');
    final createdCount = await ReferralService.instance
        .createReferralCodesForAllExistingUsers();
    print('✅ Đã tạo mã ref cho $createdCount users');

    // 2. Test lấy mã ref của từng user
    print('\n🔍 Test 2: Lấy mã ref của từng user...');
    final testUserIds = [
      'dcca23f3-ad27-4954-935b-9bf66ea4b7ce', // long sang vo
      '0a0220d4-51ec-428e-b185-1914093db584', // SABO
      '6f7c1e71-7070-4268-8edb-3ce6ca1ef197', // LOSA
      'a049617d-a35e-4224-94ee-958e4b6f9ca7', // LOSA Administrator
    ];

    for (final userId in testUserIds) {
      final code = await ReferralService.instance.getUserReferralCode(userId);
      print('👤 User $userId: Mã ref = $code');
    }

    // 3. Test tạo QR data với mã ref tích hợp
    print('\n📱 Test 3: Tạo QR data với mã ref tích hợp...');
    for (final userId in testUserIds) {
      // Tạo UserProfile tạm thời để test (trong thực tế sẽ lấy từ database)
      final testUser = UserProfile(
        id: userId,
        email: 'test@example.com',
        fullName: 'Test User',
        displayName: 'Test User',
        role: 'player',
        skillLevel: 'beginner',
        totalWins: 0,
        totalLosses: 0,
        totalTournaments: 0,
        eloRating: 1000,
        spaPoints: 0,
        totalPrizePool: 0.0,
        isVerified: false,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final qrData = await ShareService.generateUserQRDataWithReferral(
        testUser,
      );
      print('📱 User $userId: QR data = $qrData');
    }

    // 4. Test xử lý deep link
    print('\n🔗 Test 4: Xử lý deep link với mã ref...');
    final testUrls = [
      'https://saboarena.com/user/dcca23f3-ad27-4954-935b-9bf66ea4b7ce?ref=LONGSANG1',
      'https://saboarena.com/user/0a0220d4-51ec-428e-b185-1914093db584?ref=SABO2024',
    ];

    for (final url in testUrls) {
      final result = await DeepLinkService.instance.handleQRCodeUrl(url);
      print('🔗 URL: $url → Result: $result');
    }

    // 5. Test thống kê referral
    print('\n📊 Test 5: Thống kê referral...');
    for (final userId in testUserIds) {
      final stats = await ReferralService.instance.getReferralStats(userId);
      print('📊 User $userId: Stats = $stats');
    }

    print('\n🎉 Tất cả tests hoàn thành thành công!');
  } catch (error) {
    print('❌ Lỗi trong quá trình test: $error');
    print('💡 Kiểm tra:');
    print('- Database connection');
    print('- ReferralService methods');
    print('- ShareService methods');
    print('- DeepLinkService methods');
  }
}

// Cách chạy trong Flutter app:
// 1. Thêm hàm này vào một màn hình test hoặc admin screen
// 2. Gọi: await runCompleteReferralSystemTest();
// 3. Xem kết quả trong console/logs
