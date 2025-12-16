import 'dart:io';
import 'package:supabase/supabase.dart';

Future<void> main() async {
  print('🛠️  CREATING MISSING TABLES...\n');

  const supabaseUrl = 'https://mogjjvscxjwvhtpkrlqr.supabase.co';
  const serviceKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo';

  try {
    final supabase = SupabaseClient(supabaseUrl, serviceKey);

    print('1. Creating post_likes table...');
    await supabase.rpc(
      'sql',
      params: {
        'sql': '''
        CREATE TABLE IF NOT EXISTS post_likes (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
          user_id UUID REFERENCES users(id) ON DELETE CASCADE,
          created_at TIMESTAMPTZ DEFAULT NOW(),
          UNIQUE(post_id, user_id)
        );
        
        ALTER TABLE post_likes ENABLE ROW LEVEL SECURITY;
        
        CREATE POLICY "Post likes are publicly readable" ON post_likes FOR SELECT USING (true);
        CREATE POLICY "Users can like posts" ON post_likes FOR INSERT WITH CHECK (auth.uid() = user_id);
        CREATE POLICY "Users can unlike posts" ON post_likes FOR DELETE USING (auth.uid() = user_id);
        
        CREATE INDEX IF NOT EXISTS idx_post_likes_post ON post_likes(post_id);
        CREATE INDEX IF NOT EXISTS idx_post_likes_user ON post_likes(user_id);
      ''',
      },
    );
    print('   ✅ post_likes table created');

    print('\n2. Creating notifications table...');
    await supabase.rpc(
      'sql',
      params: {
        'sql': '''
        CREATE TABLE IF NOT EXISTS notifications (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          user_id UUID REFERENCES users(id) ON DELETE CASCADE,
          type VARCHAR(50) NOT NULL,
          title VARCHAR(200) NOT NULL,
          message TEXT NOT NULL,
          data JSONB,
          is_read BOOLEAN DEFAULT false,
          read_at TIMESTAMPTZ,
          created_at TIMESTAMPTZ DEFAULT NOW()
        );
        
        ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
        
        CREATE POLICY "Users can view own notifications" ON notifications FOR SELECT USING (auth.uid() = user_id);
        CREATE POLICY "Users can update own notifications" ON notifications FOR UPDATE USING (auth.uid() = user_id);
        
        CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
        CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(user_id, is_read, created_at DESC);
      ''',
      },
    );
    print('   ✅ notifications table created');

    print('\n✅ ALL MISSING TABLES CREATED SUCCESSFULLY!');
  } catch (e) {
    print('❌ ERROR: $e');
    exit(1);
  }

  exit(0);
}
