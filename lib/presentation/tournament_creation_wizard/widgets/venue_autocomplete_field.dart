import 'package:flutter/material.dart';
import 'package:sabo_arena/utils/size_extensions.dart';
import 'package:sabo_arena/theme/theme_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/auth_service.dart';
import '../../../services/club_service.dart';
// ELON_MODE_AUTO_FIX

/// Autocomplete field for venue with suggestions from:
/// 1. User's clubs
/// 2. Previously used venues
class VenueAutocompleteField extends StatefulWidget {
  final String value;
  final Function(String) onChanged;
  final String? errorText;
  final bool isValid;

  const VenueAutocompleteField({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.isValid = true,
  });

  @override
  State<VenueAutocompleteField> createState() => _VenueAutocompleteFieldState();
}

class _VenueAutocompleteFieldState extends State<VenueAutocompleteField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.value;
    _loadSuggestions();

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() => _showSuggestions = true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    final suggestions = <String>[];

    // 1. Get user's club address
    try {
      final userId = AuthService.instance.currentUser?.id;
      if (userId != null) {
        final club = await ClubService.instance.getClubByOwnerId(userId);
        if (club != null && club.address != null && club.address!.isNotEmpty) {
          suggestions.add(club.address!);
        }
      }
    } catch (e) {
      // Ignore error
    }

    // 2. Get previously used venues from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final previousVenues = prefs.getStringList('previous_venues') ?? [];
      suggestions.addAll(previousVenues);
      // Ignore error
    } catch (e) {
      // REMOVED: debugPrint('Error loading venues: $e');
    }

    // Remove duplicates and sort
    final uniqueSuggestions = suggestions.toSet().toList();
    uniqueSuggestions.sort();

    if (mounted) {
      setState(() {
        _suggestions = uniqueSuggestions;
      });
    }
  }

  Future<void> _saveVenue(String venue) async {
    if (venue.trim().isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final previousVenues = prefs.getStringList('previous_venues') ?? [];

      // Add to beginning if not exists
      if (!previousVenues.contains(venue)) {
        previousVenues.insert(0, venue);

        // Keep only last 10 venues
        if (previousVenues.length > 10) {
          previousVenues.removeRange(10, previousVenues.length);
        }

        await prefs.setStringList('previous_venues', previousVenues);
      }
      // Ignore error
    } catch (e) {
      // REMOVED: debugPrint('Error saving venue: $e');
    }
  }

  void _selectSuggestion(String suggestion) {
    _controller.text = suggestion;
    widget.onChanged(suggestion);
    _saveVenue(suggestion);
    setState(() => _showSuggestions = false);
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Icon(Icons.location_on, color: context.appTheme.primary, size: 20),
            SizedBox(width: 8.w),
            Text(
              'Địa điểm tổ chức',
              style: TextStyle(
                fontSize: 16.h,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              ' *',
              style: TextStyle(
                fontSize: 16.h,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),

        // Input field
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.errorText != null
                  ? Colors.red
                  : widget.isValid && _controller.text.isNotEmpty
                  ? Colors.green
                  : Colors.grey.shade300,
              width: widget.errorText != null ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'VD: CLB Billiards XYZ, 123 Đường ABC, Quận 1, TP.HCM',
                  hintStyle: TextStyle(
                    fontSize: 14.h,
                    color: Colors.grey.shade400,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16.w),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey.shade400),
                          onPressed: () {
                            _controller.clear();
                            widget.onChanged('');
                            setState(() {});
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  widget.onChanged(value);
                  setState(() {
                    _showSuggestions =
                        value.isEmpty ||
                        _suggestions.any(
                          (s) => s.toLowerCase().contains(value.toLowerCase()),
                        );
                  });
                },
                onTap: () {
                  setState(() => _showSuggestions = true);
                },
              ),

              // Suggestions dropdown
              if (_showSuggestions && _suggestions.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  constraints: BoxConstraints(maxHeight: 200.h),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      final isMatch =
                          _controller.text.isNotEmpty &&
                          suggestion.toLowerCase().contains(
                            _controller.text.toLowerCase(),
                          );

                      if (_controller.text.isNotEmpty && !isMatch) {
                        return const SizedBox.shrink();
                      }

                      return InkWell(
                        onTap: () => _selectSuggestion(suggestion),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade100),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.history,
                                size: 18,
                                color: Colors.grey.shade600,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  suggestion,
                                  style: TextStyle(
                                    fontSize: 14.h,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: Colors.grey.shade400,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),

        // Helper text
        if (widget.errorText == null)
          Padding(
            padding: EdgeInsets.only(top: 8.h, left: 12.w),
            child: Text(
              'Địa chỉ chi tiết giúp người chơi dễ tìm đến',
              style: TextStyle(fontSize: 12.h, color: Colors.grey.shade600),
            ),
          ),

        // Error text
        if (widget.errorText != null)
          Padding(
            padding: EdgeInsets.only(top: 8.h, left: 12.w),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 14, color: Colors.red),
                SizedBox(width: 4.w),
                Text(
                  widget.errorText!,
                  style: TextStyle(fontSize: 12.h, color: Colors.red),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

