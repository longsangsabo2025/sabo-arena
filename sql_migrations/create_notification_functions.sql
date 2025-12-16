-- Create function to send notification (bypasses RLS)
-- This function runs with SECURITY DEFINER (as database owner)
CREATE OR REPLACE FUNCTION send_notification(
  p_user_id UUID,
  p_title TEXT,
  p_message TEXT,
  p_type TEXT,
  p_data JSONB DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER -- Run as database owner, bypass RLS
SET search_path = public
AS $$
DECLARE
  v_notification_id UUID;
BEGIN
  -- Insert notification
  INSERT INTO notifications (
    user_id,
    title,
    message,
    type,
    data,
    is_read,
    is_dismissed,
    created_at
  )
  VALUES (
    p_user_id,
    p_title,
    p_message,
    p_type,
    COALESCE(p_data, '{}'::jsonb),
    false,
    false,
    NOW()
  )
  RETURNING id INTO v_notification_id;

  RETURN v_notification_id;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION send_notification TO authenticated;
GRANT EXECUTE ON FUNCTION send_notification TO anon;

-- Create function for batch notifications
CREATE OR REPLACE FUNCTION send_batch_notifications(
  p_notifications JSONB
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_notification JSONB;
  v_count INTEGER := 0;
BEGIN
  -- Loop through notifications array
  FOR v_notification IN SELECT * FROM jsonb_array_elements(p_notifications)
  LOOP
    INSERT INTO notifications (
      user_id,
      title,
      message,
      type,
      data,
      is_read,
      is_dismissed,
      created_at
    )
    VALUES (
      (v_notification->>'user_id')::UUID,
      v_notification->>'title',
      v_notification->>'message',
      v_notification->>'type',
      COALESCE(v_notification->'data', '{}'::jsonb),
      false,
      false,
      NOW()
    );
    
    v_count := v_count + 1;
  END LOOP;

  RETURN v_count;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION send_batch_notifications TO authenticated;
GRANT EXECUTE ON FUNCTION send_batch_notifications TO anon;

-- Test function
-- SELECT send_notification(
--   '00000000-0000-0000-0000-000000000000'::UUID,
--   'Test Title',
--   'Test Message',
--   'test',
--   '{"test": "data"}'::jsonb
-- );
