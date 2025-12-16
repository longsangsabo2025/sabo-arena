#!/usr/bin/env dart
// Script để tạo mã ref cho tất cả users hiện có
// Chạy script này trong Flutter app của bạn

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sabo_arena/services/referral_service.dart';

void main() async {
  // Đảm bảo Flutter binding được khởi tạo
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 Bắt đầu tạo mã ref cho tất cả users hiện có...');

  try {
    // Gọi method tạo mã ref cho tất cả users chưa có
    final createdCount = await ReferralService.instance
        .createReferralCodesForAllExistingUsers();

    print('✅ Hoàn thành! Đã tạo mã ref cho $createdCount users');
    print('');
    print('📋 Các users còn lại đã có mã ref từ trước');
    print('');
    print(
      '💡 Bạn có thể chạy lại script này bất cứ lúc nào để tạo mã ref cho users mới',
    );
  } catch (error) {
    print('❌ Lỗi khi tạo mã ref: $error');
    print('');
    print('🔧 Khắc phục:');
    print('1. Kiểm tra kết nối database');
    print('2. Đảm bảo bảng referral_codes tồn tại');
    print('3. Kiểm tra quyền truy cập database');
  }

  exit(0);
}
