// 📋 HƯỚNG DẪN CHẠY MIGRATION TẠO MÃ REF CHO USERS HIỆN CÓ
//
// Bạn có thể chạy đoạn code này trong Flutter app của mình:
//
// Cách 1: Trong một màn hình admin hoặc debug screen
// Cách 2: Trong method main() hoặc app initialization
// Cách 3: Trong một nút button đặc biệt để chạy migration

import 'package:sabo_arena/services/referral_service.dart';

// Hàm để chạy migration (copy và paste vào app của bạn)
Future<void> runReferralCodeMigration() async {
  print('🔄 Bắt đầu tạo mã ref cho tất cả users hiện có...');

  try {
    // Gọi method tạo mã ref cho tất cả users chưa có
    final createdCount = await ReferralService.instance
        .createReferralCodesForAllExistingUsers();

    print('✅ Hoàn thành! Đã tạo mã ref cho $createdCount users');

    // Hiển thị kết quả cho user (nếu có UI)
    // showSuccessDialog('Đã tạo mã ref cho $createdCount users');
  } catch (error) {
    print('❌ Lỗi khi tạo mã ref: $error');

    // Hiển thị lỗi cho user (nếu có UI)
    // showErrorDialog('Lỗi tạo mã ref: $error');
  }
}

// Ví dụ sử dụng trong Flutter app:
//
// 1. Trong một nút button:
// ElevatedButton(
//   onPressed: () async => await runReferralCodeMigration(),
//   child: Text('Tạo mã ref cho tất cả users'),
// )
//
// 2. Trong app initialization (chỉ chạy 1 lần):
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await runReferralCodeMigration(); // Chạy migration
//   runApp(MyApp());
// }
//
// 3. Trong admin screen:
// class AdminScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Admin Panel')),
//       body: Center(
//         child: ElevatedButton(
//           onPressed: runReferralCodeMigration,
//           child: Text('Run Referral Migration'),
//         ),
//       ),
//     );
//   }
// }
