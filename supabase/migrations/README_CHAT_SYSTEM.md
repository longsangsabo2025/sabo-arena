# Chat System Migration

## Overview
This migration creates the complete chat/messaging system for Sabo Arena app, including:
- Chat rooms (channels) associated with clubs
- Real-time messaging between club members
- Message replies and attachments
- Room member management with roles
- Last read tracking for unread message counts

## Tables Created

### 1. `chat_rooms`
Store chat rooms/channels for clubs.

**Columns:**
- `id` - UUID primary key
- `club_id` - Reference to clubs table
- `name` - Room name (e.g., "General", "Announcements")
- `description` - Optional room description
- `type` - Room type (general, announcement, private, etc.)
- `is_private` - Whether room requires invitation
- `is_active` - Soft delete flag
- `created_by` - User who created the room
- `created_at`, `updated_at` - Timestamps

**Indexes:**
- `club_id` - For filtering rooms by club
- `created_by` - For finding user's created rooms
- `is_active` - For filtering active rooms
- `updated_at` - For sorting by recent activity

### 2. `chat_messages`
Individual messages sent in chat rooms.

**Columns:**
- `id` - UUID primary key
- `room_id` - Reference to chat_rooms
- `sender_id` - User who sent the message
- `message` - Message text content
- `message_type` - Type: text, image, file, system
- `reply_to` - Optional reference to another message (for replies)
- `attachments` - JSONB array of attachment URLs
- `is_deleted` - Soft delete flag
- `created_at`, `updated_at` - Timestamps

**Indexes:**
- `room_id` - For fetching room messages
- `sender_id` - For user's message history
- `(room_id, created_at)` - For efficient message pagination
- `reply_to` - For reply threads
- `is_deleted` - For filtering deleted messages

### 3. `chat_room_members`
Track users who are members of chat rooms.

**Columns:**
- `room_id` - Reference to chat_rooms
- `user_id` - Reference to users
- `role` - Member role: admin, moderator, member
- `last_read_at` - Timestamp of last message read (for unread counts)
- `joined_at` - When user joined the room

**Primary Key:** `(room_id, user_id)` - Composite key

**Indexes:**
- `user_id` - For user's room memberships
- `room_id` - For room's member list
- `role` - For filtering by role

## Row Level Security (RLS)

### chat_rooms
- **SELECT**: Users can view rooms they are members of, or public non-private rooms
- **INSERT**: Club members can create rooms in their clubs
- **UPDATE**: Room admins can update room settings
- **DELETE**: Room admins can delete (deactivate) rooms

### chat_messages
- **SELECT**: Room members can view messages in their rooms
- **INSERT**: Room members can send messages (sender_id must match auth.uid())
- **UPDATE**: Users can update their own messages only
- **DELETE**: Users can soft-delete their own messages

### chat_room_members
- **SELECT**: Room members can view other members in their rooms
- **INSERT**: Users can join public rooms, or admins can add members
- **UPDATE**: Users can update their own membership (e.g., last_read_at), or admins can update roles
- **DELETE**: Users can leave rooms, or admins can remove members

## Realtime Subscriptions

The following tables are enabled for Supabase Realtime:
- `chat_messages` - For instant message delivery
- `chat_rooms` - For room updates (name, description changes)
- `chat_room_members` - For member join/leave notifications

## Usage in Code

See `lib/services/chat_service.dart` for implementation:

```dart
// Get chat rooms
final rooms = await ChatService.getChatRooms(clubId: clubId);

// Create a room
final room = await ChatService.createChatRoom(
  clubId: clubId,
  name: 'General',
  description: 'General discussion',
);

// Send a message
await ChatService.sendMessage(
  roomId: roomId,
  message: 'Hello!',
);

// Subscribe to messages
final channel = ChatService.subscribeToMessages(
  roomId: roomId,
  onMessage: (message) {
    print('New message: ${message['message']}');
  },
);
```

## Foreign Key Constraints

Named foreign keys for use in queries:
- `chat_messages_sender_id_fkey` - Links messages to users (sender)
- `chat_messages_reply_to_fkey` - Links messages to parent messages (replies)

## Migration Status

✅ Created: 2025-01-14
⚠️  Status: **NOT YET APPLIED TO DATABASE**

**Important Note:** 
The tables already exist in the Supabase production database but were created manually without a migration file. This migration file documents the schema and ensures it can be recreated in other environments (staging, development, etc.).

## Applying This Migration

### For New Environments
Run this migration using Supabase CLI:
```bash
supabase db push
```

### For Existing Production Database
⚠️ **DO NOT RUN ON PRODUCTION** - Tables already exist!

If you need to update the schema, create a new migration file with ALTER statements instead.

## Related Files
- `lib/services/chat_service.dart` - Chat service implementation
- `lib/presentation/messaging_screen/messaging_screen.dart` - Chat UI
- `lib/routes/app_routes.dart` - Routing configuration
