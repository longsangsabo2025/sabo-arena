import 'package:flutter/material.dart';
import 'dart:async';
import '../services/optimized_realtime_service.dart';
import '../services/messaging_service.dart';

/// 🚀 TESLA-OPTIMIZED Messaging Screen
class OptimizedMessagingScreen extends StatefulWidget {
  final String? chatId;
  final String? chatName;

  const OptimizedMessagingScreen({super.key, this.chatId, this.chatName});

  @override
  State<OptimizedMessagingScreen> createState() => _OptimizedMessagingScreenState();
}

class _OptimizedMessagingScreenState extends State<OptimizedMessagingScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final OptimizedRealtimeService _realtimeService = OptimizedRealtimeService();
  final MessagingService _messagingService = MessagingService.instance;

  List<Map<String, dynamic>> _messages = [];
  final Map<String, dynamic> _userCache = {}; // 🚀 CACHE user data instead of JOINing
  String? _selectedChatId;
  String? _selectedChatName;
  bool _isLoading = false;
  bool _isTyping = false;
  String? _lastMessageTimestamp; // For cursor pagination
  StreamSubscription<RealtimeEvent>? _messageSubscription;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _selectedChatId = widget.chatId;
    _selectedChatName = widget.chatName;
    
    if (_selectedChatId != null) {
      _initializeChat();
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _typingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    
    if (_selectedChatId != null) {
      _realtimeService.disconnectFromRoom(_selectedChatId!);
    }
    
    super.dispose();
  }

  /// 🚀 INITIALIZE chat with optimized loading
  Future<void> _initializeChat() async {
    if (_selectedChatId == null) return;
    
    try {
      setState(() => _isLoading = true);
      
      // Connect to real-time service
      await _realtimeService.connectToRoom(_selectedChatId!, 'current_user_id');
      
      // Subscribe to message events
      _messageSubscription = _realtimeService
          .subscribeToEvent(RealtimeEventType.message, _selectedChatId)
          .listen(_handleRealtimeMessage);
      
      // Load initial messages
      await _loadMessages();
      
    } catch (e) {
      _showError('Failed to initialize chat: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🚀 LOAD messages with cursor pagination (no OFFSET!)
  Future<void> _loadMessages({bool isLoadingMore = false}) async {
    if (_selectedChatId == null) return;
    
    try {
      final messages = await _messagingService.getChatMessages(
        _selectedChatId!,
        limit: 50,
        beforeTimestamp: isLoadingMore ? _lastMessageTimestamp : null,
      );
      
      // Cache user data for all senders
      await _cacheUsersForMessages(messages);
      
      setState(() {
        if (isLoadingMore) {
          _messages.addAll(messages);
        } else {
          _messages = messages;
        }
        
        if (messages.isNotEmpty) {
          _lastMessageTimestamp = messages.last['created_at'];
        }
      });
      
      if (!isLoadingMore && _messages.isNotEmpty) {
        _scrollToBottom();
      }
      
    } catch (e) {
      _showError('Failed to load messages: $e');
    }
  }

  /// 🚀 CACHE user data separately (no expensive JOINs)
  Future<void> _cacheUsersForMessages(List<Map<String, dynamic>> messages) async {
    final userIds = messages
        .map((msg) => msg['sender_id'] as String)
        .where((id) => !_userCache.containsKey(id))
        .toSet();
    
    for (final userId in userIds) {
      final userData = await _messagingService.getUserData(userId);
      if (userData != null) {
        _userCache[userId] = userData;
      }
    }
  }

  /// 🚀 HANDLE real-time message events
  void _handleRealtimeMessage(RealtimeEvent event) {
    final data = event.data as Map<String, dynamic>;
    final action = data['action'] as String;
    
    switch (action) {
      case 'insert':
        final newMessage = data['message'] as Map<String, dynamic>;
        setState(() {
          _messages.insert(0, newMessage); // Add to top (newest first)
        });
        
        // Cache user data if not cached
        final senderId = newMessage['sender_id'] as String;
        if (!_userCache.containsKey(senderId)) {
          _messagingService.getUserData(senderId).then((userData) {
            if (userData != null) {
              setState(() => _userCache[senderId] = userData);
            }
          });
        }
        
        _scrollToBottom();
        break;
        
      case 'update':
        final updatedMessage = data['message'] as Map<String, dynamic>;
        setState(() {
          final index = _messages.indexWhere((msg) => msg['id'] == updatedMessage['id']);
          if (index != -1) {
            _messages[index] = updatedMessage;
          }
        });
        break;
        
      case 'delete':
        final messageId = data['messageId'] as String;
        setState(() {
          _messages.removeWhere((msg) => msg['id'] == messageId);
        });
        break;
    }
  }

  /// 🚀 SEND message with optimized UI updates
  Future<void> _sendMessage() async {
    if (_selectedChatId == null || _messageController.text.trim().isEmpty) return;
    
    final messageContent = _messageController.text.trim();
    _messageController.clear();
    
    // Stop typing indicator
    _setTyping(false);
    
    try {
      final success = await _messagingService.sendMessage(
        roomId: _selectedChatId!,
        content: messageContent,
      );
      
      if (!success) {
        _showError('Failed to send message');
        // Restore message content for retry
        _messageController.text = messageContent;
      }
    } catch (e) {
      _showError('Error sending message: $e');
      _messageController.text = messageContent;
    }
  }

  /// 🚀 TYPING indicator with debouncing
  void _onTextChanged(String text) {
    if (text.isNotEmpty && !_isTyping) {
      _setTyping(true);
    }
    
    // Reset typing timer
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _setTyping(false);
    });
  }

  void _setTyping(bool isTyping) {
    if (_isTyping == isTyping) return;
    
    setState(() => _isTyping = isTyping);
    
    if (_selectedChatId != null) {
      _realtimeService.sendTypingIndicator(_selectedChatId!, 'current_user_id', isTyping);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    final senderId = message['sender_id'] as String;
    final content = message['content'] as String;
    final timestamp = DateTime.parse(message['created_at']);
    final userData = _userCache[senderId];
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: userData?['avatar_url'] != null 
                ? NetworkImage(userData!['avatar_url'])
                : null,
            child: userData?['avatar_url'] == null
                ? Text(userData?['full_name']?[0] ?? 'U')
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      userData?['full_name'] ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(content),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedChatName ?? 'Messages'),
        actions: [
          if (_realtimeService.isConnected)
            const Icon(Icons.circle, color: Colors.green, size: 12)
          else
            const Icon(Icons.circle, color: Colors.red, size: 12),
        ],
      ),
      body: Column(
        children: [
          // Messages list with infinite scroll
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : NotificationListener<ScrollNotification>(
                    onNotification: (scrollInfo) {
                      // Load more when near bottom
                      if (scrollInfo.metrics.pixels > scrollInfo.metrics.maxScrollExtent * 0.8) {
                        _loadMessages(isLoadingMore: true);
                      }
                      return false;
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return _buildMessage(_messages[index]);
                      },
                    ),
                  ),
          ),
          
          // Typing indicator
          if (_isTyping)
            Container(
              padding: const EdgeInsets.all(8),
              child: const Text('You are typing...', style: TextStyle(fontStyle: FontStyle.italic)),
            ),
          
          // Message input
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onChanged: _onTextChanged,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}