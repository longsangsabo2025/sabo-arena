// 🎯 SCRIPT TẠO 32 DEMO USERS HOÀN CHỈNH

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sabo_arena/services/auth_service.dart';
import 'package:sabo_arena/services/referral_service.dart';

/// Widget để tạo và quản lý demo users
class DemoUsersManager extends StatefulWidget {
  const DemoUsersManager({super.key});

  @override
  _DemoUsersManagerState createState() => _DemoUsersManagerState();
}

class _DemoUsersManagerState extends State<DemoUsersManager> {
  bool _isCreating = false;
  String _status = 'Sẵn sàng tạo demo users';
  int _createdCount = 0;
  final List<String> _createdUsers = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Demo Users Manager'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trạng thái',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _status,
                      style: TextStyle(
                        color: _isCreating ? Colors.orange : Colors.green,
                        fontSize: 16,
                      ),
                    ),
                    if (_createdCount > 0) ...[
                      SizedBox(height: 8),
                      Text(
                        'Đã tạo: $_createdCount users',
                        style: TextStyle(fontSize: 14, color: Colors.blue),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isCreating ? null : _createDemoUsers,
                    icon: _isCreating
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.person_add),
                    label: Text('Tạo 32 Demo Users'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Users List
            if (_createdUsers.isNotEmpty) ...[
              Text(
                'Users đã tạo:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _createdUsers.length,
                  itemBuilder: (context, index) {
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text('${index + 1}')),
                        title: Text(_createdUsers[index]),
                        subtitle: Text('Demo user ${index + 1}'),
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Chưa có demo users nào',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Nhấn nút bên trên để tạo 32 demo users',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _createDemoUsers() async {
    setState(() {
      _isCreating = true;
      _status = 'Đang tạo demo users...';
      _createdCount = 0;
      _createdUsers.clear();
    });

    final random = Random();

    // Danh sách tên để tạo users đa dạng
    final firstNames = [
      'Nguyễn',
      'Trần',
      'Lê',
      'Phạm',
      'Hoàng',
      'Đỗ',
      'Bùi',
      'Vũ',
      'Ngô',
      'Đinh',
      'Lý',
      'Tạ',
      'Phan',
      'Trương',
      'Đào',
      'Cao',
    ];

    final lastNames = [
      'Anh',
      'Bình',
      'Cường',
      'Dung',
      'Em',
      'Phong',
      'Quang',
      'Hồng',
      'Yên',
      'Zung',
      'Minh',
      'Hà',
      'Linh',
      'Nam',
      'Hoa',
      'Tú',
    ];

    int successCount = 0;

    for (int i = 1; i <= 32; i++) {
      try {
        // Tạo thông tin ngẫu nhiên
        final firstName = firstNames[random.nextInt(firstNames.length)];
        final lastName = lastNames[random.nextInt(lastNames.length)];
        final fullName = '$firstName $lastName';

        final email = 'demo${i.toString().padLeft(3, '0')}@saboarena.com';
        final password = 'DemoPass${i.toString().padLeft(3, '0')}!';

        setState(() {
          _status = 'Đang tạo user $i/32: $fullName...';
        });

        // Tạo user thông qua AuthService
        final response = await AuthService.instance.signUpWithEmail(
          email: email,
          password: password,
          fullName: fullName,
          role: 'player',
        );

        if (response.user != null) {
          successCount++;
          _createdUsers.add('$fullName ($email)');

          setState(() {
            _createdCount = successCount;
          });

          // Đợi một chút để tránh rate limiting
          await Future.delayed(Duration(milliseconds: 300));
        } else {
          print('⚠️ Không thể tạo user: $fullName');
        }
      } catch (e) {
        print('❌ Lỗi tạo user $i: $e');
      }
    }

    setState(() {
      _isCreating = false;
      _status = 'Hoàn thành! Đã tạo $successCount demo users';
    });

    // Đợi một chút để các users được tạo hoàn toàn
    await Future.delayed(Duration(seconds: 2));

    // Tạo mã ref cho tất cả users hiện có
    setState(() {
      _status = 'Đang tạo mã ref cho tất cả users...';
    });

    try {
      final refCreatedCount = await ReferralService.instance
          .createReferralCodesForAllExistingUsers();

      setState(() {
        _status =
            'Hoàn thành! Đã tạo $successCount demo users và $refCreatedCount mã ref';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Đã tạo $successCount demo users và $refCreatedCount mã ref!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      setState(() {
        _status = 'Lỗi tạo mã ref: $error';
      });
    }
  }
}

/// Hàm tiện ích để tạo demo users từ bất kỳ đâu trong app
Future<int> createDemoUsersQuick() async {
  print('🚀 Tạo nhanh 32 demo users...');

  final random = Random();
  final firstNames = ['Nguyễn', 'Trần', 'Lê', 'Phạm', 'Hoàng'];
  final lastNames = ['Anh', 'Bình', 'Cường', 'Dung', 'Em'];

  int createdCount = 0;

  for (int i = 1; i <= 32; i++) {
    try {
      final firstName = firstNames[random.nextInt(firstNames.length)];
      final lastName = lastNames[random.nextInt(lastNames.length)];
      final fullName = '$firstName $lastName';

      final email = 'demo${i.toString().padLeft(3, '0')}@test.com';
      final password = 'DemoPass$i!';

      final response = await AuthService.instance.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (response.user != null) {
        createdCount++;
        print('✅ Đã tạo: $fullName');
      }

      // Đợi để tránh rate limiting
      await Future.delayed(Duration(milliseconds: 200));
    } catch (e) {
      print('❌ Lỗi tạo user $i: $e');
    }
  }

  // Tạo mã ref cho tất cả users
  try {
    final refCount = await ReferralService.instance
        .createReferralCodesForAllExistingUsers();
    print('🎯 Đã tạo mã ref cho $refCount users');
  } catch (e) {
    print('❌ Lỗi tạo mã ref: $e');
  }

  return createdCount;
}

// Cách sử dụng:
// 1. Copy class DemoUsersManager vào app của bạn
// 2. Thêm route: '/demo-users': (context) => DemoUsersManager()
// 3. Hoặc gọi hàm: await createDemoUsersQuick()
// 4. Chạy app và truy cập để tạo demo users
