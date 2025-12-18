import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../widgets/custom_image_widget.dart';
// ELON_MODE_AUTO_FIX

class CreatePostHintWidget extends StatefulWidget {
  final VoidCallback onTap;

  const CreatePostHintWidget({super.key, required this.onTap});

  @override
  State<CreatePostHintWidget> createState() => _CreatePostHintWidgetState();
}

class _CreatePostHintWidgetState extends State<CreatePostHintWidget> {
  final _supabase = Supabase.instance.client;
  String? _userAvatarUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserAvatar();
  }

  Future<void> _loadUserAvatar() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await _supabase
          .from('users')
          .select('avatar_url')
          .eq('id', userId)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _userAvatarUrl = response['avatar_url'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use avatar URL or fallback to default
    final avatarUrl =
        _userAvatarUrl ??
        'https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white, // Facebook: pure white
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE4E6EB), // Facebook: divider
            width: 8,
          ),
        ),
      ),
      child: Row(
        children: [
          // Avatar with loading state
          ClipOval(
            child: _isLoading
                ? Container(
                    width: 40,
                    height: 40,
                    color: const Color(0xFFF0F2F5),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF65676B),
                          ),
                        ),
                      ),
                    ),
                  )
                : CustomImageWidget(
                    imageUrl: avatarUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(width: 8), // Facebook: 8px gap
          // Input hint
          Expanded(
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5), // Facebook: background gray
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Bạn đang nghĩ gì?',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF65676B), // Facebook: gray600
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Photo button
          GestureDetector(
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.photo_library,
                color: Color(0xFF45BD62), // Facebook: green
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

