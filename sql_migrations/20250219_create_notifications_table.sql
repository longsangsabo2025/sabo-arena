-- 🚀 ELON MODE: Notifications table for direct user notifications
-- Stores in-app notifications for tournament completion, rewards, etc.

CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Notification content
  type TEXT NOT NULL, -- 'tournament_completion', 'match_result', 'challenge_received', etc.
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  icon TEXT, -- 'trophy', 'medal', 'info', 'warning', etc.
  
  -- Metadata (JSON with tournament_id, position, rewards, etc.)
  data JSONB,
  
  -- Status
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMPTZ,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Indexes for performance
  INDEX idx_notifications_user_id (user_id),
  INDEX idx_notifications_created_at (created_at DESC),
  INDEX idx_notifications_is_read (is_read),
  INDEX idx_notifications_type (type)
);

-- Enable RLS (Row Level Security)
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own notifications
CREATE POLICY "Users can view own notifications"
  ON notifications
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can mark their notifications as read
CREATE POLICY "Users can update own notifications"
  ON notifications
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Policy: System can insert notifications for any user
CREATE POLICY "System can insert notifications"
  ON notifications
  FOR INSERT
  WITH CHECK (true); -- Backend service has full access

-- Add updated_at trigger
CREATE TRIGGER update_notifications_updated_at
  BEFORE UPDATE ON notifications
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE notifications IS '🚀 ELON MODE: Direct user notifications for tournaments, rewards, challenges, etc.';
COMMENT ON COLUMN notifications.type IS 'Type of notification: tournament_completion, match_result, challenge_received, etc.';
COMMENT ON COLUMN notifications.data IS 'JSON metadata (tournament_id, position, spa_reward, elo_change, prize_money, etc.)';
COMMENT ON COLUMN notifications.icon IS 'Icon identifier: trophy, medal, info, warning, etc.';
