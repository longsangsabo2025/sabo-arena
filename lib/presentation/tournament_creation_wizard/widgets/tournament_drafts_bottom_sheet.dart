import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/tournament_draft_service.dart';
import '../tournament_creation_wizard.dart';

/// Widget hiển thị danh sách drafts và cho phép quản lý
class TournamentDraftsBottomSheet extends StatefulWidget {
  final Function(Map<String, dynamic>)? onDraftSelected;

  const TournamentDraftsBottomSheet({super.key, this.onDraftSelected});

  @override
  State<TournamentDraftsBottomSheet> createState() =>
      _TournamentDraftsBottomSheetState();
}

class _TournamentDraftsBottomSheetState
    extends State<TournamentDraftsBottomSheet> {
  final TournamentDraftService _draftService = TournamentDraftService.instance;
  List<Map<String, dynamic>> _drafts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    setState(() => _isLoading = true);

    final drafts = await _draftService.getAllDrafts();

    if (mounted) {
      setState(() {
        _drafts = drafts;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(20.sp),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Icon(Icons.drafts, color: Colors.blue, size: 24.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Quản lý bản nháp',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, size: 24.sp),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _drafts.isEmpty
                ? _buildEmptyState()
                : _buildDraftsList(),
          ),

          // Bottom actions
          Container(
            padding: EdgeInsets.all(20.sp),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TournamentCreationWizard(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Tạo giải đấu mới',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_add_outlined,
            size: 64.sp,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16.h),
          Text(
            'Chưa có bản nháp nào',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Bắt đầu tạo giải đấu để lưu bản nháp',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDraftsList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      itemCount: _drafts.length,
      itemBuilder: (context, index) {
        final draft = _drafts[index];
        final isAutoSave = draft['isAutoSave'] == true;
        final updatedAt = DateTime.parse(draft['updatedAt']);

        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _selectDraft(draft),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(16.sp),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              isAutoSave ? Icons.auto_mode : Icons.edit_note,
                              color: isAutoSave ? Colors.orange : Colors.blue,
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                draft['name'] ?? 'Nháp không tên',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) => _handleDraftAction(value, draft),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'rename',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20.sp),
                                SizedBox(width: 8.w),
                                Text('Đổi tên'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'duplicate',
                            child: Row(
                              children: [
                                Icon(Icons.copy, size: 20.sp),
                                SizedBox(width: 8.w),
                                Text('Tạo bản sao'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 20.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Xóa',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                        child: Icon(Icons.more_vert, size: 20.sp),
                      ),
                    ],
                  ),

                  SizedBox(height: 12.h),

                  // Tournament info
                  if (draft['data'] != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.sports_esports,
                          size: 16.sp,
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          draft['data']['gameType'] ?? 'Chưa chọn',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Icon(
                          Icons.people,
                          size: 16.sp,
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          '${draft['data']['maxParticipants'] ?? 0} người',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                  ],

                  // Time info
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14.sp,
                              color: Colors.grey.shade500,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Cập nhật: ${_formatDate(updatedAt)}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isAutoSave)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Tự động',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) {
      return '${diff.inDays} ngày trước';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  void _selectDraft(Map<String, dynamic> draft) {
    Navigator.pop(context);
    if (widget.onDraftSelected != null) {
      widget.onDraftSelected!(draft);
    } else {
      // Navigate to creation wizard with draft data
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TournamentCreationWizard(draftData: draft),
        ),
      );
    }
  }

  void _handleDraftAction(String action, Map<String, dynamic> draft) async {
    switch (action) {
      case 'rename':
        await _showRenameDialog(draft);
        break;
      case 'duplicate':
        await _duplicateDraft(draft);
        break;
      case 'delete':
        await _deleteDraft(draft);
        break;
    }
  }

  Future<void> _showRenameDialog(Map<String, dynamic> draft) async {
    final controller = TextEditingController(text: draft['name']);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Đổi tên bản nháp'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Tên bản nháp',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text('Lưu'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != draft['name']) {
      await _draftService.renameDraft(draft['id'], result);
      await _loadDrafts();
    }
  }

  Future<void> _duplicateDraft(Map<String, dynamic> draft) async {
    try {
      final newName = '${draft['name']} (Bản sao)';
      await _draftService.duplicateDraft(draft['id'], newName);
      await _loadDrafts();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Đã tạo bản sao thành công')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tạo bản sao: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteDraft(Map<String, dynamic> draft) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa bản nháp "${draft['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _draftService.deleteDraft(draft['id']);
      await _loadDrafts();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Đã xóa bản nháp')));
      }
    }
  }
}
