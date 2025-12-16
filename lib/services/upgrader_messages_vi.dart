import 'package:upgrader/upgrader.dart';

/// Vietnamese messages for Upgrader package
/// Customize app update dialog messages in Vietnamese
class UpgraderMessagesVi extends UpgraderMessages {
  @override
  String get buttonTitleIgnore => 'Bỏ qua';

  @override
  String get buttonTitleLater => 'Để sau';

  @override
  String get buttonTitleUpdate => 'Cập nhật ngay';

  @override
  String get prompt =>
      'Phiên bản mới của SABO Arena đã có sẵn. Bạn có muốn cập nhật ngay?';

  @override
  String get title => 'Cập nhật ứng dụng';

  @override
  String? message(UpgraderMessage message) =>
      'Phiên bản mới đã có sẵn với nhiều tính năng và cải tiến mới!';

  @override
  String get releaseNotes => 'Thông tin phiên bản';
}
