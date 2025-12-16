// 🎯 Home Feed Tutorial - Coach Marks cho trang chủ
// Hướng dẫn user các chức năng chính trên trang chủ

import 'package:flutter/material.dart';
import '../app_coach_marks.dart';

/// 🎯 Home Feed Tutorial Steps
class HomeFeedTutorialSteps {
  /// Tạo danh sách tutorial steps cho home feed
  static List<CoachMarkStep> createSteps({
    required GlobalKey homeFeedKey,
    required GlobalKey createPostKey,
    required GlobalKey clubsKey,
    required GlobalKey tournamentsKey,
    required GlobalKey profileKey,
  }) {
    return [
      // Step 1: Giới thiệu trang chủ
      CoachMarkStep(
        targetKey: homeFeedKey,
        title: 'Trang Chủ',
        description:
            'Nơi để bạn khám phá các bài viết mới nhất từ cộng đồng Bida, '
            'theo dõi hoạt động của các câu lạc bộ và kết nối với những người chơi khác.',
        position: CoachMarkPosition.bottom,
      ),

      // Step 2: Tạo bài viết
      CoachMarkStep(
        targetKey: createPostKey,
        title: 'Tạo Bài Viết',
        description:
            'Nhấn vào đây để chia sẻ khoảnh khắc, ảnh trận đấu, '
            'hoặc những trải nghiệm của bạn với cộng đồng.',
        position: CoachMarkPosition.top,
      ),

      // Step 3: Tab Câu lạc bộ
      CoachMarkStep(
        targetKey: clubsKey,
        title: 'Câu Lạc Bộ',
        description:
            'Khám phá và tham gia các câu lạc bộ Bida trong khu vực của bạn. '
            'Kết nối với đội nhóm và tham gia các hoạt động thường xuyên.',
        position: CoachMarkPosition.top,
      ),

      // Step 4: Tab Giải đấu
      CoachMarkStep(
        targetKey: tournamentsKey,
        title: 'Giải Đấu',
        description:
            'Xem lịch thi đấu, đăng ký tham gia giải đấu và theo dõi kết quả. '
            'Cơ hội để nâng cao kỹ năng và tranh tài với các cao thủ.',
        position: CoachMarkPosition.top,
      ),

      // Step 5: Tab Cá nhân
      CoachMarkStep(
        targetKey: profileKey,
        title: 'Trang Cá Nhân',
        description:
            'Quản lý hồ sơ, xem thống kê, hạng của bạn và các thành tích đã đạt được. '
            'Đăng ký xác minh hạng để tham gia giải đấu chính thức.',
        position: CoachMarkPosition.top,
      ),
    ];
  }
}
