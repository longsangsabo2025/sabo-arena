import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class MessagingScreen extends StatefulWidget {
  final String? chatId;
  final String? chatName;

  const MessagingScreen({super.key, this.chatId, this.chatName});

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _chatRooms = [];
  String? _selectedChatId;
  String? _selectedChatName;
  RealtimeChannel? _messageSubscription;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedChatId = widget.chatId;
    _selectedChatName = widget.chatName;
    _loadChatRooms();
    if (_selectedChatId != null) {
      _loadMessages();
      _subscribeToMessages();
    }
  }

  @override
  void dispose() {
    _messageSubscription?.unsubscribe();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChatRooms() async {
    try {
      setState(() => _isLoading = true);

      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Chưa đăng nhập');
      }

      // Load rooms where user is a member
      final response = await _supabase
          .from('chat_rooms')
          .select('''
            *,
            chat_room_members!inner(user_id)
          ''')
          .eq('chat_room_members.user_id', user.id)
          .order('updated_at', ascending: false);

      if (mounted) {
        setState(() {
          _chatRooms = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải danh sách chat: $e')));
      }
    }
  }

  Future<void> _loadMessages() async {
    if (_selectedChatId == null) return;

    try {
      final response = await _supabase
          .from('chat_messages')
          .select('''
            *,
            users!chat_messages_sender_id_fkey(
              id,
              display_name,
              avatar_url
            )
          ''')
          .eq('room_id', _selectedChatId!)
          .eq('is_deleted', false)
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(response);
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải tin nhắn: $e')));
      }
    }
  }

  void _subscribeToMessages() {
    if (_selectedChatId == null) return;

    _messageSubscription?.unsubscribe();
    _messageSubscription = _supabase
        .channel('messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id', // Fixed: chat_room_id -> room_id
            value: _selectedChatId,
          ),
          callback: (payload) {
            if (mounted) {
              _loadMessages();
            }
          },
        )
        .subscribe();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _selectedChatId == null)
      return;

    final content = _messageController.text.trim();
    _messageController.clear();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Chưa đăng nhập');
      }

      await _supabase.from('chat_messages').insert({
        'room_id': _selectedChatId, // Fixed: chat_room_id -> room_id
        'sender_id': user.id,
        'message': content, // Fixed: content -> message
        'message_type': 'text',
      });

      if (!mounted) return;
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi gửi tin nhắn: $e')));
      }
    }
  }

  Future<void> _createNewChat() async {
    final nameController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tạo phòng chat mới'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Tên phòng chat',
            hintText: 'Nhập tên phòng chat...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: Text('Tạo'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (result != null && result.isNotEmpty) {
      try {
        final user = _supabase.auth.currentUser;
        if (user == null) throw Exception('Chưa đăng nhập');

        // Note: Need to create room with club_id
        // For now, we'll use a temporary approach
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tính năng tạo phòng chat cần được gọi từ màn hình club với club_id',
            ),
            duration: Duration(seconds: 3),
          ),
        );

        // TODO: Implement proper room creation with club context
        // final response = await _supabase
        //     .from('chat_rooms')
        //     .insert({
        //       'club_id': clubId,  // Required field
        //       'name': result,
        //       'created_by': user.id,
        //       'type': 'general',  // Fixed: room_type -> type
        //     })
        //     .select()
        //     .single();
        //
        // _loadChatRooms();
        // _selectChat(response['id'], response['name']);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tạo phòng chat: $e')));
      }
    }
  }

  void _selectChat(String chatId, String chatName) {
    _messageSubscription?.unsubscribe();
    setState(() {
      _selectedChatId = chatId;
      _selectedChatName = chatName;
      _messages.clear();
    });
    _loadMessages();
    _subscribeToMessages();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(String createdAt) {
    final dateTime = DateTime.parse(createdAt);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else {
      return '${difference.inDays} ngày trước';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedChatName ?? 'Tin nhắn SABO Arena'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: Icon(Icons.add_comment), onPressed: _createNewChat),
          if (_selectedChatId != null)
            IconButton(icon: Icon(Icons.refresh), onPressed: _loadMessages),
        ],
      ),
      body: Row(
        children: [
          // Chat list sidebar
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(right: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.chat, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Danh sách chat', overflow: TextOverflow.ellipsis, style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: _chatRooms.length,
                          itemBuilder: (context, index) {
                            final chat = _chatRooms[index];
                            final isSelected = chat['id'] == _selectedChatId;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor,
                                child: Icon(Icons.group, color: Colors.white),
                              ),
                              title: Text(
                                chat['name'] ?? 'Unnamed Chat', overflow: TextOverflow.ellipsis, style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                _formatTime(chat['created_at']),
                                style: TextStyle(fontSize: 12),
                              ),
                              selected: isSelected,
                              selectedTileColor: Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.1),
                              onTap: () =>
                                  _selectChat(chat['id'], chat['name']),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // Chat messages area
          Expanded(
            child: _selectedChatId == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Chọn một phòng chat để bắt đầu', overflow: TextOverflow.ellipsis, style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _createNewChat,
                          icon: Icon(Icons.add),
                          label: Text('Tạo phòng chat mới'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Messages list
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.all(8),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final isCurrentUser =
                                message['sender_id'] ==
                                _supabase.auth.currentUser?.id;
                            final senderName =
                                message['users']?['display_name'] ?? 'Unknown';

                            return Align(
                              alignment: isCurrentUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 8,
                                ),
                                padding: EdgeInsets.all(12),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.7,
                                ),
                                decoration: BoxDecoration(
                                  color: isCurrentUser
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!isCurrentUser)
                                      Padding(
                                        padding: EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          senderName, style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).primaryColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      message['message'] ?? '', overflow: TextOverflow.ellipsis, style: TextStyle(
                                        color: isCurrentUser
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      _formatTime(message['created_at']),
                                      style: TextStyle(
                                        color: isCurrentUser
                                            ? Colors.white70
                                            : Colors.grey[600],
                                        fontSize: 12,
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
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: 'Nhập tin nhắn...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                maxLines: null,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            SizedBox(width: 8),
                            FloatingActionButton(
                              onPressed: _sendMessage,
                              mini: true,
                              child: Icon(Icons.send),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
