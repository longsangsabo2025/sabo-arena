import 'package:supabase_flutter/supabase_flutter.dart';

/// Quick fix for chat_rooms schema - adds missing columns
/// Run this once to fix the "user1_id does not exist" error
void main() async {
  print('🔧 Starting database schema fix for chat_rooms...');

  // Initialize Supabase with service role
  final supabaseUrl = 'https://mogjjvscxjwvhtpkrlqr.supabase.co';
  final serviceRoleKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo';

  final supabase = SupabaseClient(supabaseUrl, serviceRoleKey);

  try {
    print('💾 Adding missing columns to chat_rooms table...');

    // Add missing columns
    await supabase.rpc(
      'exec_sql',
      params: {
        'sql': '''
        -- Add missing columns for direct messaging
        ALTER TABLE chat_rooms 
        ADD COLUMN IF NOT EXISTS user1_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
        ADD COLUMN IF NOT EXISTS user2_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
        ADD COLUMN IF NOT EXISTS room_type VARCHAR(20) DEFAULT 'group',
        ADD COLUMN IF NOT EXISTS last_message_at TIMESTAMPTZ DEFAULT NOW();
      ''',
      },
    );

    print('✅ Columns added successfully!');

    print('🔍 Creating performance indexes...');

    // Create indexes for better performance
    await supabase.rpc(
      'exec_sql',
      params: {
        'sql': '''
        -- Create index for better performance on direct message queries
        CREATE INDEX IF NOT EXISTS idx_chat_rooms_direct_messages 
        ON chat_rooms(user1_id, user2_id) 
        WHERE room_type = 'direct';
        
        -- Create index for user-based lookups
        CREATE INDEX IF NOT EXISTS idx_chat_rooms_user1 ON chat_rooms(user1_id);
        CREATE INDEX IF NOT EXISTS idx_chat_rooms_user2 ON chat_rooms(user2_id);
      ''',
      },
    );

    print('✅ Indexes created successfully!');

    print('📝 Updating existing room types...');

    // Update existing rooms
    await supabase.rpc(
      'exec_sql',
      params: {
        'sql': '''
        -- Update existing rooms to have proper room_type
        UPDATE chat_rooms 
        SET room_type = 'group' 
        WHERE room_type IS NULL;
      ''',
      },
    );

    print('✅ Existing rooms updated!');

    print('🎉 Database schema fix completed successfully!');
    print('');
    print('📊 Summary of changes:');
    print('   ✅ Added user1_id column (UUID, references auth.users)');
    print('   ✅ Added user2_id column (UUID, references auth.users)');
    print('   ✅ Added room_type column (VARCHAR, default: group)');
    print('   ✅ Added last_message_at column (TIMESTAMPTZ)');
    print('   ✅ Created performance indexes');
    print('   ✅ Updated existing room types');
    print('');
    print('🚀 Messaging system should now work without errors!');
  } catch (e) {
    print('❌ Error fixing database schema: $e');
    print('');
    print('💡 Possible solutions:');
    print('   1. Make sure service role key is correct');
    print('   2. Check if exec_sql function exists in database');
    print('   3. Verify database permissions');
  }
}
