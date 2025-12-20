import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Local database cache for messages
/// Implements caching strategy similar to WhatsApp/Messenger:
/// 1. Load from cache first (instant)
/// 2. Sync with server in background
/// 3. Listen to real-time updates
///
/// NOTE: Disabled on web platform (sqflite not supported)
class MessagesCacheService {
  static Database? _database;

  /// Check if caching is available (disabled on web and desktop)
  static bool get isAvailable {
    if (kIsWeb) return false;
    // Disable on desktop platforms as sqflite requires ffi setup which might be missing
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return false;
    }
    return true;
  }

  /// Get database instance (singleton)
  static Future<Database?> get database async {
    if (!isAvailable) return null; // Disabled on web
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database with tables
  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'messages_cache.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create conversations table
        await db.execute('''
          CREATE TABLE conversations (
            room_id TEXT PRIMARY KEY,
            other_user_id TEXT NOT NULL,
            other_user_name TEXT NOT NULL,
            other_user_avatar TEXT,
            last_message TEXT,
            last_message_time TEXT NOT NULL,
            unread_count INTEGER DEFAULT 0,
            updated_at TEXT NOT NULL,
            synced_at TEXT NOT NULL
          )
        ''');

        // Create messages table
        await db.execute('''
          CREATE TABLE messages (
            id TEXT PRIMARY KEY,
            room_id TEXT NOT NULL,
            sender_id TEXT NOT NULL,
            message TEXT NOT NULL,
            created_at TEXT NOT NULL,
            synced_at TEXT NOT NULL,
            FOREIGN KEY (room_id) REFERENCES conversations (room_id)
          )
        ''');

        // Create indexes for performance
        await db.execute('''
          CREATE INDEX idx_messages_room_id ON messages(room_id)
        ''');

        await db.execute('''
          CREATE INDEX idx_messages_created_at ON messages(created_at)
        ''');

        await db.execute('''
          CREATE INDEX idx_conversations_updated_at ON conversations(updated_at)
        ''');
      },
    );
  }

  /// Cache a conversation
  static Future<void> cacheConversation({
    required String roomId,
    required String otherUserId,
    required String otherUserName,
    String? otherUserAvatar,
    String? lastMessage,
    required String lastMessageTime,
    int unreadCount = 0,
    required String updatedAt,
  }) async {
    if (!isAvailable) return; // Skip on web
    final db = await database;
    if (db == null) return;
    await db.insert(
        'conversations',
        {
          'room_id': roomId,
          'other_user_id': otherUserId,
          'other_user_name': otherUserName,
          'other_user_avatar': otherUserAvatar,
          'last_message': lastMessage,
          'last_message_time': lastMessageTime,
          'unread_count': unreadCount,
          'updated_at': updatedAt,
          'synced_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get all cached conversations
  static Future<List<Map<String, dynamic>>> getCachedConversations() async {
    if (!isAvailable) return []; // Return empty on web
    final db = await database;
    if (db == null) return [];
    return await db.query('conversations', orderBy: 'updated_at DESC');
  }

  /// Cache a message
  static Future<void> cacheMessage({
    required String id,
    required String roomId,
    required String senderId,
    required String message,
    required String createdAt,
  }) async {
    if (!isAvailable) return; // Skip on web
    final db = await database;
    if (db == null) return;
    await db.insert(
        'messages',
        {
          'id': id,
          'room_id': roomId,
          'sender_id': senderId,
          'message': message,
          'created_at': createdAt,
          'synced_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get cached messages for a room
  static Future<List<Map<String, dynamic>>> getCachedMessages(
    String roomId,
  ) async {
    if (!isAvailable) return []; // Return empty on web
    final db = await database;
    if (db == null) return [];
    return await db.query(
      'messages',
      where: 'room_id = ?',
      whereArgs: [roomId],
      orderBy: 'created_at ASC',
    );
  }

  /// Update last message in conversation
  static Future<void> updateConversationLastMessage({
    required String roomId,
    required String lastMessage,
    required String lastMessageTime,
  }) async {
    if (!isAvailable) return; // Skip on web
    final db = await database;
    if (db == null) return;
    await db.update(
      'conversations',
      {
        'last_message': lastMessage,
        'last_message_time': lastMessageTime,
        'updated_at': lastMessageTime,
        'synced_at': DateTime.now().toIso8601String(),
      },
      where: 'room_id = ?',
      whereArgs: [roomId],
    );
  }

  /// Update unread count
  static Future<void> updateUnreadCount(String roomId, int count) async {
    if (!isAvailable) return; // Skip on web
    final db = await database;
    if (db == null) return;
    await db.update(
      'conversations',
      {'unread_count': count},
      where: 'room_id = ?',
      whereArgs: [roomId],
    );
  }

  /// Clear all cache (useful for logout)
  static Future<void> clearCache() async {
    if (!isAvailable) return; // Skip on web
    final db = await database;
    if (db == null) return;
    await db.delete('messages');
    await db.delete('conversations');
  }

  /// Delete specific conversation and its messages
  static Future<void> deleteConversation(String roomId) async {
    if (!isAvailable) return; // Skip on web
    final db = await database;
    if (db == null) return;
    await db.delete('messages', where: 'room_id = ?', whereArgs: [roomId]);
    await db.delete('conversations', where: 'room_id = ?', whereArgs: [roomId]);
  }
}
