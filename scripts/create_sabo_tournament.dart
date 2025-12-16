import 'dart:convert';
import 'package:http/http.dart' as http;

/// 🔐 SECURITY FIX: Uses environment variables instead of hardcoded keys
/// Run with: dart run create_sabo_tournament.dart --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_SERVICE_ROLE_KEY=...
void main() async {
  // 🚨 SECURITY: Get from environment variables, NEVER hardcode
  const url = String.fromEnvironment('SUPABASE_URL');
  const serviceRoleKey = String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY');
  
  if (url.isEmpty || serviceRoleKey.isEmpty) {
    print('❌ ERROR: Missing required environment variables!');
    print('Usage: dart run create_sabo_tournament.dart \\');
    print('  --dart-define=SUPABASE_URL=https://your-project.supabase.co \\');
    print('  --dart-define=SUPABASE_SERVICE_ROLE_KEY=your-service-role-key');
    print('');
    print('⚠️  SECURITY: Never commit service role keys to version control!');
    return;
  }

  print('🚀 Creating SABO Tournament...');

  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $serviceRoleKey',
    'apikey': serviceRoleKey,
    'Prefer': 'return=representation'
  };

  // 1. Get an organizer ID (first user found)
  String? organizerId;
  /*
  try {
    final userResponse = await http.get(
      Uri.parse('$url/rest/v1/profiles?select=id&limit=1'),
      headers: headers,
    );

    if (userResponse.statusCode == 200) {
      final users = jsonDecode(userResponse.body) as List;
      if (users.isNotEmpty) {
        organizerId = users[0]['id'];
        print('✅ Found organizer ID: $organizerId');
      } else {
        print('⚠️ No users found. Creating without organizer.');
      }
    } else {
      print('❌ Failed to fetch users: ${userResponse.body}');
    }
  } catch (e) {
    print('❌ Error fetching users: $e');
  }
  */

  // 2. Prepare Tournament Data
  final tournamentData = {
    "title": "🔥 SABO TOURNAMENT POOL 9 BALL: RANK I - K 🔥",
    "description": "⏰ Thời gian: 09:00 Sáng | Thứ Sáu (12/12/2025).\n📍 Địa điểm: SABO Billiards - 601A Nguyễn An Ninh, TP. Vũng Tàu.\n👥 Đối tượng: Hạng I & Hạng K.\n💸 Lệ phí: 100k/slot (Thi đấu 2 mạng - Thua trả tiền bàn).\n🎱 Số lượng: 16 VĐV.\n🥇 CƠ CẤU GIẢI THƯỞNG\nChampions: 1.000.000 VNĐ + 500k Voucher + Bảng vinh danh\nRunner-up: 400.000 VNĐ + 300k Voucher + Bảng vinh danh\n3rd Place (x2): 100.000 VNĐ + 150k Voucher + Bảng vinh danh\nTop 5 - 8: Voucher 50k\n🎯THỂ LỆ THI ĐẤU\nThể Thức: 9 Bi | Xếp Thấp | Phá Luân Phiên | 3 Bi Về Bếp | 3 Lỗi Quốc Tế\n⚖️Tỷ Lệ Chấp:\nI chấp K: 1 ván.\nĐồng cơ (I-I, K-K): Chạm 6.\nTứ kết: Chạm 7.\nBán kết: Chạm 7.\nChung kết: Chạm 9.\n⚠️ QUY ĐỊNH TỪ BTC\nVĐV đăng ký tự ý bỏ giải không hoàn lệ phí.\nPhát hiện gian lận hạng (Bịp hạng) 👉 LOẠI TRỰC TIẾP (Không hoàn tiền).\nQuyết định của BTC là cuối cùng.\n👉 Tham gia Group Zalo “CỘNG ĐỒNG SABO” để cập nhật các giải đấu và sự kiện mới nhất: https://zalo.me/g/ouanzv519\n👉 Tải app SABO ARENA trên App Store/CH Play để đăng ký thành viên\n📞 LIÊN HỆ ĐĂNG KÝ:\n☎️ Zalo: 0329.640.232\n📍Check-in: SABO Billiards Club - 601A Nguyễn An Ninh, TP. Vũng Tàu",
    "start_date": "2025-12-12T09:00:00",
    "registration_deadline": "2025-12-12T08:00:00",
    "max_participants": 16,
    "current_participants": 0,
    "entry_fee": 100000,
    "prize_pool": 1600000,
    "status": "upcoming",
    "game_format": "9-ball",
    "bracket_format": "double_elimination",
    "is_public": true,
    "prize_source": "entry_fees",
    "distribution_template": "custom",
    "organizer_fee_percent": 0,
    "sponsor_contribution": 0,
    "min_rank": "K",
    "max_rank": "I",
    "venue_address": "SABO Billiards - 601A Nguyễn An Ninh, TP. Vũng Tàu",
    "venue_contact": "Zalo: 0329.640.232",
    "venue_phone": "0329640232",
    "special_rules": "I chấp K: 1 ván. Đồng cơ (I-I, K-K): Chạm 6. Tứ kết: Chạm 7. Bán kết: Chạm 7. Chung kết: Chạm 9. 3 Bi Về Bếp | 3 Lỗi Quốc Tế",
    "registration_fee_waiver": false,
    "custom_distribution": [
      {"position": 1, "percentage": 62.5},
      {"position": 2, "percentage": 25.0},
      {"position": 3, "percentage": 6.25},
      {"position": 4, "percentage": 6.25}
    ]
  };

  // organizerId is currently always null (commented out fetch logic)
  // if (organizerId != null) {
  //   tournamentData['organizer_id'] = organizerId;
  // }

  // 3. Insert Tournament
  try {
    final response = await http.post(
      Uri.parse('$url/rest/v1/tournaments'),
      headers: headers,
      body: jsonEncode(tournamentData),
    );

    if (response.statusCode == 201) {
      print('✅ Tournament created successfully!');
      print('Response: ${response.body}');
    } else {
      print('❌ Failed to create tournament: ${response.statusCode}');
      print('Body: ${response.body}');
    }
  } catch (e) {
    print('❌ Error creating tournament: $e');
  }
}
