import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:sabo_arena/core/design_system/responsive_grid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:sabo_arena/widgets/user/user_widgets.dart';

import '../../models/user_profile.dart';
import '../../services/messages_cache_service.dart';
import '../../services/direct_messaging_service.dart';
import '../../core/utils/user_display_name.dart';
import '../other_user_profile_screen/other_user_profile_screen.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Direct Messages Screen - Meta Messenger style
/// Features:
/// - List of 1-1 conversations
/// - Recent message preview
/// - Unread count badges
/// - Search users to start new chat
/// - Real-time message updates
class DirectMessagesScreen extends StatefulWidget {
  const DirectMessagesScreen({super.key});

  @override
  State<DirectMessagesScreen> createState() => _DirectMessagesScreenState();
}

class _DirectMessagesScreenState extends State<DirectMessagesScreen> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _conversations = [];
  List<UserProfile> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;
  bool _showSearch = false;

  RealtimeChannel? _messagesChannel;

  @override
  void initState() {
    super.initState();
    // Initialize Vietnamese locale for timeago
    timeago.setLocaleMessages('vi', timeago.ViMessages());
    _loadConversations();
    _subscribeToMessages();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messagesChannel?.unsubscribe();
    super.dispose();
  }

  /// Load all 1-1 conversations for current user
  /// Strategy: Load from cache first (instant), then sync with server
  Future<void> _loadConversations() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        setState(() => _isLoading = false);
        return;
      }

      ProductionLogger.info('🔍 Loading conversations for user: $currentUserId', tag: 'direct_messages_screen');

      // STEP 1: Load from cache first (instant)
      final cachedConversations =
          await MessagesCacheService.getCachedConversations();
      if (cachedConversations.isNotEmpty) {
        ProductionLogger.info('⚡ Loaded ${cachedConversations.length} conversations from cache',  tag: 'direct_messages_screen');
        setState(() {
          _conversations = cachedConversations
              .map(
                (c) => {
                  'roomId': c['room_id'],
                  'otherUser': {
                    'id': c['other_user_id'],
                    'display_name': c['other_user_name'],
                    'avatar_url': c['other_user_avatar'],
                  },
                  'lastMessage': c['last_message'] ?? 'Bắt đầu trò chuyện',
                  'lastMessageTime': c['last_message_time'],
                  'unreadCount': c['unread_count'] ?? 0,
                  'updatedAt': c['updated_at'],
                },
              )
              .toList();
          _isLoading = false;
        });
      }

      // STEP 3: Sync with server in background
      ProductionLogger.info('� Syncing with server...', tag: 'direct_messages_screen');

      // NEW APPROACH: Query chat_rooms with JOIN to members directly
      ProductionLogger.info('🔍 Querying chat_rooms joined with members...', tag: 'direct_messages_screen');
      final rooms = await _supabase
          .from('chat_rooms')
          .select(
            'id, created_at, updated_at, chat_room_members!inner(user_id)',
          )
          .eq('type', 'direct')
          .eq('chat_room_members.user_id', currentUserId)
          .order('updated_at', ascending: false);

      ProductionLogger.info('💬 Found ${rooms.length} direct message rooms', tag: 'direct_messages_screen');

      if (rooms.isEmpty) {
        ProductionLogger.info('📭 No conversations found', tag: 'direct_messages_screen');
        setState(() {
          _conversations = [];
          _isLoading = false;
        });
        return;
      }

      List<Map<String, dynamic>> conversations = [];

      // Step 4: Process each room
      for (var room in rooms) {
        try {
          // Get all members (should be exactly 2)
          final members = await _supabase
              .from('chat_room_members')
              .select('user_id')
              .eq('room_id', room['id']);

          if (members.length != 2) {
            ProductionLogger.info('⚠️  Room ${room['id']} has ${members.length} members, skipping',  tag: 'direct_messages_screen');
            continue;
          }

          // Find the other user
          final otherUserId = members.firstWhere(
            (m) => m['user_id'] != currentUserId,
          )['user_id'];

          // Get other user's profile
          final otherUser = await _supabase
              .from('users')
              .select('id, display_name, avatar_url')
              .eq('id', otherUserId)
              .maybeSingle();

          if (otherUser == null) {
            ProductionLogger.info('⚠️  User $otherUserId not found, skipping', tag: 'direct_messages_screen');
            continue;
          }

          // Get last message
          final lastMessage = await _supabase
              .from('chat_messages')
              .select('message, created_at, sender_id')
              .eq('room_id', room['id'])
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();

          final conversationData = {
            'roomId': room['id'],
            'otherUser': otherUser,
            'lastMessage': lastMessage?['message'] ?? 'Bắt đầu trò chuyện',
            'lastMessageTime': lastMessage?['created_at'] ?? room['created_at'],
            'unreadCount': 0, // TODO: Calculate unread count
            'updatedAt': room['updated_at'],
          };

          conversations.add(conversationData);

          // Cache this conversation
          await MessagesCacheService.cacheConversation(
            roomId: room['id'],
            otherUserId: otherUser['id'],
            otherUserName: otherUser['display_name'],
            otherUserAvatar: otherUser['avatar_url'],
            lastMessage: lastMessage?['message'],
            lastMessageTime: lastMessage?['created_at'] ?? room['created_at'],
            unreadCount: 0,
            updatedAt: room['updated_at'],
          );
        } catch (e) {
          ProductionLogger.info('❌ Error processing room ${room['id']}: $e', tag: 'direct_messages_screen');
        }
      }

      ProductionLogger.info('✅ Synced ${conversations.length} conversations from server', tag: 'direct_messages_screen');

      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      ProductionLogger.info('❌ Error loading conversations: $e', tag: 'direct_messages_screen');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải tin nhắn: $e')));
      }
    }
  }

  /// Subscribe to real-time message updates
  void _subscribeToMessages() {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    _messagesChannel = _supabase
        .channel('direct_messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          callback: (payload) {
            // Reload conversations when new message arrives
            _loadConversations();
          },
        )
        .subscribe();
  }

  /// Search users to start new conversation
  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    try {
      setState(() => _isSearching = true);

      final currentUserId = _supabase.auth.currentUser?.id;

      final users = await _supabase
          .from('users')
          .select('*')
          .neq('id', currentUserId!)
          .or('display_name.ilike.%$query%,email.ilike.%$query%')
          .limit(20);

      setState(() {
        _searchResults = users.map((u) => UserProfile.fromJson(u)).toList();
        _isSearching = false;
      });
    } catch (e) {
      ProductionLogger.info('Error searching users: $e', tag: 'direct_messages_screen');
      setState(() => _isSearching = false);
    }
  }

  /// Start or open conversation with a user
  Future<void> _openConversation(
    String otherUserId,
    String otherUserName,
  ) async {
    try {
      // ✅ Use centralized service - Single Source of Truth
      final roomId = await DirectMessagingService.instance
          .getOrCreateDirectRoom(otherUserId);

      if (!mounted) return;

      // Get other user info from existing conversation or search results
      String? otherUserAvatar;
      final existingConversation = _conversations.firstWhere(
        (c) => c['otherUser']['id'] == otherUserId,
        orElse: () => {},
      );
      if (existingConversation.isNotEmpty) {
        otherUserAvatar = existingConversation['otherUser']['avatar_url'];
      }

      // Open conversation
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DirectChatScreen(
            roomId: roomId,
            otherUserId: otherUserId,
            otherUserName: otherUserName,
            otherUserAvatar: otherUserAvatar,
          ),
        ),
      );

      // Refresh list after returning
      _loadConversations();
      setState(() => _showSearch = false);
    } catch (e) {
      ProductionLogger.info('Error opening conversation: $e', tag: 'direct_messages_screen');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi mở cuộc trò chuyện: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm người dùng...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey[400]),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: _searchUsers,
              )
            : const Text('Tin nhắn'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  _searchResults = [];
                }
              });
            },
          ),
        ],
      ),
      body: _showSearch ? _buildSearchView() : _buildConversationsList(),
    );
  }

  Widget _buildSearchView() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey[300]),
            SizedBox(height: 2.h),
            Text(
              'Tìm kiếm người dùng để nhắn tin', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 80, color: Colors.grey[300]),
            SizedBox(height: 2.h),
            Text(
              'Không tìm thấy người dùng', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return ListTile(
          leading: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OtherUserProfileScreen(
                  userId: user.id,
                  userName: user.displayName,
                ),
              ),
            ),
            child: UserAvatarWidget(
              avatarUrl: user.avatarUrl,
              size: 40,
            ),
          ),
          title: Text(user.displayName),
          subtitle: Text(user.email),
          onTap: () => _openConversation(user.id, user.displayName),
        );
      },
    );
  }

  Widget _buildConversationsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
            SizedBox(height: 2.h),
            Text(
              'Chưa có tin nhắn nào', overflow: TextOverflow.ellipsis, style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Tìm kiếm người dùng để bắt đầu chat', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
            ),
            SizedBox(height: 3.h),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _showSearch = true);
              },
              icon: const Icon(Icons.search),
              label: const Text('Tìm kiếm người dùng'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          final otherUser = conversation['otherUser'];
          final lastMessage = conversation['lastMessage'] as String;
          final unreadCount = conversation['unreadCount'] as int;
          final lastMessageTime = DateTime.parse(
            conversation['lastMessageTime'],
          );

          return ListTile(
            leading: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OtherUserProfileScreen(
                    userId: otherUser['id'],
                    userName: otherUser['display_name'],
                  ),
                ),
              ),
              child: Stack(
                children: [
                  UserAvatarWidget(
                    avatarUrl: otherUser['avatar_url'],
                    size: 56,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.all(0.5.w),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(
                          minWidth: 4.w,
                          minHeight: 4.w,
                        ),
                        child: Center(
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            title: Text(
              UserDisplayName.fromMap(otherUser),
              style: TextStyle(
                fontWeight: unreadCount > 0
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              lastMessage.isEmpty ? 'Bắt đầu cuộc trò chuyện' : lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis, style: TextStyle(
                color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                fontWeight: unreadCount > 0
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
            ),
            trailing: Text(
              timeago.format(lastMessageTime, locale: 'vi'),
              style: TextStyle(
                fontSize: 11.sp,
                color: unreadCount > 0
                    ? Theme.of(context).primaryColor
                    : Colors.grey[500],
                fontWeight: unreadCount > 0
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            onTap: () => _openConversation(
              otherUser['id'],
              UserDisplayName.fromMap(otherUser),
            ),
          );
        },
      ),
    );
  }
}

/// Direct Chat Screen - Individual conversation view
class DirectChatScreen extends StatefulWidget {
  final String roomId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;

  const DirectChatScreen({
    super.key,
    required this.roomId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
  });

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final _supabase = Supabase.instance.client;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _showEmojiPicker = false;

  RealtimeChannel? _messagesChannel;

  // Popular emojis list (Facebook Messenger style)
  final List<String> _emojis = [
    '😀',
    '😃',
    '😄',
    '😁',
    '😆',
    '😅',
    '🤣',
    '😂',
    '🙂',
    '🙃',
    '😉',
    '😊',
    '😇',
    '🥰',
    '😍',
    '🤩',
    '😘',
    '😗',
    '😚',
    '😙',
    '🥲',
    '😋',
    '😛',
    '😜',
    '🤪',
    '😝',
    '🤑',
    '🤗',
    '🤭',
    '🤫',
    '🤔',
    '🤐',
    '🤨',
    '😐',
    '😑',
    '😶',
    '😏',
    '😒',
    '🙄',
    '😬',
    '🤥',
    '😌',
    '😔',
    '😪',
    '🤤',
    '😴',
    '😷',
    '🤒',
    '🤕',
    '🤢',
    '🤮',
    '🤧',
    '🥵',
    '🥶',
    '😶‍🌫️',
    '🥴',
    '😵',
    '🤯',
    '🤠',
    '🥳',
    '🥸',
    '😎',
    '🤓',
    '🧐',
    '😕',
    '😟',
    '🙁',
    '☹️',
    '😮',
    '😯',
    '😲',
    '😳',
    '🥺',
    '😦',
    '😧',
    '😨',
    '😰',
    '😥',
    '😢',
    '😭',
    '😱',
    '😖',
    '😣',
    '😞',
    '😓',
    '😩',
    '😫',
    '🥱',
    '😤',
    '😡',
    '😠',
    '🤬',
    '😈',
    '👿',
    '💀',
    '☠️',
    '💩',
    '🤡',
    '👹',
    '👺',
    '👻',
    '👽',
    '👾',
    '🤖',
    '😺',
    '😸',
    '😹',
    '😻',
    '😼',
    '😽',
    '🙀',
    '😿',
    '😾',
    '❤️',
    '🧡',
    '💛',
    '💚',
    '💙',
    '💜',
    '🖤',
    '🤍',
    '🤎',
    '💔',
    '❤️‍🔥',
    '❤️‍🩹',
    '❣️',
    '💕',
    '💞',
    '💓',
    '💗',
    '💖',
    '💘',
    '💝',
    '💟',
    '☮️',
    '✝️',
    '☪️',
    '🕉️',
    '☸️',
    '✡️',
    '🔯',
    '🕎',
    '☯️',
    '☦️',
    '🛐',
    '⛎',
    '♈',
    '♉',
    '♊',
    '♋',
    '♌',
    '♍',
    '♎',
    '♏',
    '♐',
    '♑',
    '♒',
    '♓',
    '🆔',
    '⚛️',
    '👍',
    '👎',
    '👌',
    '✌️',
    '🤞',
    '🤟',
    '🤘',
    '🤙',
    '👈',
    '👉',
    '👆',
    '👇',
    '☝️',
    '👋',
    '🤚',
    '🖐️',
    '✋',
    '🖖',
    '👏',
    '🙌',
    '👐',
    '🤲',
    '🤝',
    '🙏',
    '✍️',
    '💅',
    '🤳',
    '💪',
    '🦾',
    '🦿',
    '🦵',
    '🦶',
  ];

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeToMessages();
    _markAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _messagesChannel?.unsubscribe();
    super.dispose();
  }

  /// Load all messages in this conversation
  /// Strategy: Load from cache first (instant), then sync with server
  Future<void> _loadMessages() async {
    try {
      ProductionLogger.info('🔍 Loading messages for room: ${widget.roomId}', tag: 'direct_messages_screen');

      // STEP 1: Load from cache first (instant)
      final cachedMessages = await MessagesCacheService.getCachedMessages(
        widget.roomId,
      );
      if (cachedMessages.isNotEmpty) {
        ProductionLogger.info('⚡ Loaded ${cachedMessages.length} messages from cache', tag: 'direct_messages_screen');
        setState(() {
          _messages = cachedMessages
              .map(
                (m) => {
                  'id': m['id'],
                  'room_id': m['room_id'],
                  'sender_id': m['sender_id'],
                  'message': m['message'],
                  'created_at': m['created_at'],
                },
              )
              .toList();
          _isLoading = false;
        });

        // Scroll to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(
              _scrollController.position.maxScrollExtent,
            );
          }
        });
      } else {
        setState(() => _isLoading = true);
      }

      // STEP 2: Sync with server in background
      ProductionLogger.info('🔄 Syncing messages with server...', tag: 'direct_messages_screen');

      final messages = await _supabase
          .from('chat_messages')
          .select('*')
          .eq('room_id', widget.roomId)
          .order('created_at', ascending: true);

      ProductionLogger.info('✅ Synced ${messages.length} messages from server', tag: 'direct_messages_screen');

      // Cache all messages
      for (var message in messages) {
        await MessagesCacheService.cacheMessage(
          id: message['id'],
          roomId: message['room_id'],
          senderId: message['sender_id'],
          message: message['message'],
          createdAt: message['created_at'],
        );
      }

      setState(() {
        _messages = List<Map<String, dynamic>>.from(messages);
        _isLoading = false;
      });

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    } catch (e) {
      ProductionLogger.info('❌ Error loading messages: $e', tag: 'direct_messages_screen');
      setState(() => _isLoading = false);
    }
  }

  /// Subscribe to real-time message updates
  void _subscribeToMessages() {
    _messagesChannel = _supabase
        .channel('chat_${widget.roomId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: widget.roomId,
          ),
          callback: (payload) {
            setState(() {
              _messages.add(payload.newRecord);
            });

            // Scroll to bottom
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });

            // Mark as read
            _markAsRead();
          },
        )
        .subscribe();
  }

  /// Mark all messages in this conversation as read
  Future<void> _markAsRead() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      await _supabase
          .from('chat_room_members')
          .update({'last_read_at': DateTime.now().toIso8601String()})
          .eq('room_id', widget.roomId)
          .eq('user_id', currentUserId);
    } catch (e) {
      ProductionLogger.info('Error marking as read: $e', tag: 'direct_messages_screen');
    }
  }

  /// Send a like emoji
  Future<void> _sendLike() async {
    if (_isSending) return;

    try {
      setState(() => _isSending = true);

      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        ProductionLogger.info('❌ No current user', tag: 'direct_messages_screen');
        return;
      }

      ProductionLogger.info('👍 Sending like to room ${widget.roomId}', tag: 'direct_messages_screen');

      final result = await _supabase
          .from('chat_messages')
          .insert({
            'room_id': widget.roomId,
            'sender_id': currentUserId,
            'message': '👍',
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      ProductionLogger.info('✅ Like sent', tag: 'direct_messages_screen');

      // Cache the message
      await MessagesCacheService.cacheMessage(
        id: result['id'],
        roomId: result['room_id'],
        senderId: result['sender_id'],
        message: result['message'],
        createdAt: result['created_at'],
      );

      // Update conversation cache
      await MessagesCacheService.updateConversationLastMessage(
        roomId: widget.roomId,
        lastMessage: '👍',
        lastMessageTime: result['created_at'],
      );

      // Manually add message to list
      if (mounted) {
        setState(() {
          _messages.add(Map<String, dynamic>.from(result));
        });
      }

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      // Update room's updated_at
      await _supabase
          .from('chat_rooms')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', widget.roomId);

      setState(() => _isSending = false);
    } catch (e) {
      ProductionLogger.info('❌ Error sending like: $e', tag: 'direct_messages_screen');
      setState(() => _isSending = false);
    }
  }

  /// Send a message
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    try {
      setState(() => _isSending = true);

      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        ProductionLogger.info('❌ No current user', tag: 'direct_messages_screen');
        return;
      }

      ProductionLogger.info('📤 Sending message: "$text" to room ${widget.roomId}', tag: 'direct_messages_screen');

      final result = await _supabase
          .from('chat_messages')
          .insert({
            'room_id': widget.roomId,
            'sender_id': currentUserId,
            'message': text,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      ProductionLogger.info('✅ Message sent successfully', tag: 'direct_messages_screen');
      ProductionLogger.info('📊 Result: $result', tag: 'direct_messages_screen');

      // Cache the message
      await MessagesCacheService.cacheMessage(
        id: result['id'],
        roomId: result['room_id'],
        senderId: result['sender_id'],
        message: result['message'],
        createdAt: result['created_at'],
      );

      // Update conversation cache
      await MessagesCacheService.updateConversationLastMessage(
        roomId: widget.roomId,
        lastMessage: text,
        lastMessageTime: result['created_at'],
      );

      // Manually add message to list if realtime doesn't work
      if (mounted) {
        setState(() {
          _messages.add(Map<String, dynamic>.from(result));
        });
        ProductionLogger.info('✅ Added to list, total messages: ${_messages.length}', tag: 'direct_messages_screen');
      }

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      // Update room's updated_at
      await _supabase
          .from('chat_rooms')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', widget.roomId);

      _messageController.clear();
      setState(() => _isSending = false);
    } catch (e) {
      ProductionLogger.info('❌ Error sending message: $e', tag: 'direct_messages_screen');
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi gửi tin nhắn: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _supabase.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtherUserProfileScreen(
                userId: widget.otherUserId,
                userName: widget.otherUserName,
              ),
            ),
          ),
          child: Row(
            children: [
              UserAvatarWidget(
                avatarUrl: widget.otherUserAvatar,
                size: 36,
              ),
              SizedBox(width: 2.w),
              Text(widget.otherUserName),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 60,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Bắt đầu cuộc trò chuyện', overflow: TextOverflow.ellipsis, style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(2.w),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message['sender_id'] == currentUserId;
                      final createdAt = DateTime.parse(message['created_at']);

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.only(
                            top: 4,
                            bottom: 4,
                            left: isMe ? 60 : 8,
                            right: isMe ? 8 : 60,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? const Color(
                                    0xFF0084FF,
                                  ) // Facebook Messenger blue
                                : const Color(0xFFE4E6EB), // Facebook gray
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                message['message'], overflow: TextOverflow.ellipsis, style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black87,
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                timeago.format(createdAt, locale: 'vi'),
                                style: TextStyle(
                                  color: isMe
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Text input
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Aa',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 16,
                      ),
                      prefixIcon: IconButton(
                        icon: Text(
                          _showEmojiPicker ? '⌨️' : '😊', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20),
                        ),
                        onPressed: () {
                          if (_showEmojiPicker) {
                            // Close emoji picker, open keyboard
                            setState(() {
                              _showEmojiPicker = false;
                            });
                            _focusNode.requestFocus();
                          } else {
                            // Close keyboard, open emoji picker
                            _focusNode.unfocus();
                            setState(() {
                              _showEmojiPicker = true;
                            });
                          }
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF0F2F5),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    style: const TextStyle(fontSize: 15),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    onChanged: (_) => setState(() {}),
                    onTap: () {
                      if (_showEmojiPicker) {
                        setState(() {
                          _showEmojiPicker = false;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Send button or Like button
                _messageController.text.trim().isEmpty
                    ? IconButton(
                        icon: const Text('👍', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 28)),
                        onPressed: _isSending ? null : () => _sendLike(),
                        padding: EdgeInsets.zero,
                      )
                    : Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _isSending
                              ? Colors.grey[300]
                              : const Color(0xFF0084FF),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: _isSending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.send,
                                  size: 18,
                                  color: Colors.white,
                                ),
                          onPressed: _isSending ? null : _sendMessage,
                        ),
                      ),
              ],
            ),
          ),

          // Emoji Picker (displayed below input bar)
          if (_showEmojiPicker)
            Container(
              height: 250,
              color: const Color(0xFFF0F2F5),
              child: ResponsiveGrid(
                items: _emojis,
                itemBuilder: (context, emoji, index) {
                  return InkWell(
                    onTap: () {
                      _messageController.text += emoji;
                      setState(() {});
                    },
                    child: Center(
                      child: Text(
                        emoji,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  );
                },
                padding: const EdgeInsets.all(8),
                spacing: 8,
                runSpacing: 8,
                shrinkWrap: false,
                childAspectRatio: 1.0,
              ),
            ),
        ],
      ),
    );
  }
}
