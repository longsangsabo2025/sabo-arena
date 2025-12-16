// 🎯 ĐOẠN CODE ĐỂ CHẠY TRỰC TIẾP TRONG FLUTTER APP

import 'dart:math';
import 'package:sabo_arena/services/auth_service.dart';
import 'package:sabo_arena/services/referral_service.dart';

/// Hàm chính để tạo 32 demo users
Future<int> createDemoUsersQuick() async {
  print('🚀 Bắt đầu tạo 32 demo users...');

  final random = Random();
  final firstNames = ['Nguyễn', 'Trần', 'Lê', 'Phạm', 'Hoàng', 'Đỗ'];
  final lastNames = ['Anh', 'Bình', 'Cường', 'Dung', 'Em', 'Phong'];

  int createdCount = 0;

  for (int i = 1; i <= 32; i++) {
    try {
      // Tạo thông tin ngẫu nhiên cho user
      final firstName = firstNames[random.nextInt(firstNames.length)];
      final lastName = lastNames[random.nextInt(lastNames.length)];
      final fullName = '$firstName $lastName';

      final email = 'demo${i.toString().padLeft(3, '0')}@saboarena.com';
      final password = 'DemoPass${i.toString().padLeft(3, '0')}!';

      print('👤 Đang tạo user $i: $fullName ($email)');

      // Tạo user thông qua AuthService
      final response = await AuthService.instance.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
        role: 'player',
      );

      if (response.user != null) {
        createdCount++;
        print('✅ Đã tạo thành công: $fullName');

        // Đợi một chút để tránh rate limiting
        await Future.delayed(Duration(milliseconds: 300));
      } else {
        print('⚠️ Không thể tạo user: $fullName');
      }
    } catch (e) {
      print('❌ Lỗi tạo user $i: $e');
    }
  }

  print('\n🎉 Hoàn thành tạo demo users!');
  print('📊 Tổng cộng: $createdCount users đã tạo thành công');

  // Đợi một chút để các users được tạo hoàn toàn
  await Future.delayed(Duration(seconds: 2));

  // Tạo mã ref cho tất cả users hiện có
  print('\n🔗 Đang tạo mã ref cho tất cả users...');
  try {
    final refCreatedCount = await ReferralService.instance
        .createReferralCodesForAllExistingUsers();
    print('✅ Đã tạo mã ref cho $refCreatedCount users');
  } catch (error) {
    print('❌ Lỗi tạo mã ref: $error');
  }

  return createdCount;
}

/// CÁCH SỬ DỤNG:
///
/// 1. Copy đoạn code này vào một file trong Flutter app của bạn
///
/// 2. Import các services cần thiết:
///    import 'package:sabo_arena/services/auth_service.dart';
///    import 'package:sabo_arena/services/referral_service.dart';
///
/// 3. Gọi hàm trong một màn hình bất kỳ:
///    final count = await createDemoUsersQuick();
///    print('Đã tạo \$count demo users');
///
/// 4. Hoặc tạo một nút button để gọi:
///    ElevatedButton(
///      onPressed: () async {
///        final count = await createDemoUsersQuick();
///        ScaffoldMessenger.of(context).showSnackBar(
///          SnackBar(content: Text('Đã tạo \$count demo users!')),
///        );
///      },
///      child: Text('Tạo Demo Users'),
///    )
///
/// 5. Chạy app và nhấn nút để tạo 32 demo users tự động!
