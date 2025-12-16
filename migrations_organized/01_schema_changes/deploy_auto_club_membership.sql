-- ============================================
-- AUTO ADD USER TO CLUB AFTER RANK VERIFICATION
-- ============================================
-- When a rank request is approved, automatically add the user as a club member
-- This SQL creates a database trigger as backup for the Dart logic

-- Drop existing trigger and function if they exist
DROP TRIGGER IF EXISTS auto_add_member_on_rank_approval ON rank_requests;
DROP FUNCTION IF EXISTS auto_add_member_on_rank_approval();

-- Create function to auto-add member when rank is approved
CREATE OR REPLACE FUNCTION auto_add_member_on_rank_approval()
RETURNS TRIGGER AS $$
BEGIN
  -- Only proceed if status changed to 'approved'
  IF NEW.status = 'approved' AND (OLD.status IS NULL OR OLD.status != 'approved') THEN
    
    -- Check if user is already a member of the club
    IF NOT EXISTS (
      SELECT 1 FROM club_members 
      WHERE club_id = NEW.club_id 
      AND user_id = NEW.user_id
    ) THEN
      
      -- Add user as a regular member
      INSERT INTO club_members (
        club_id,
        user_id,
        role,
        status,
        joined_at,
        permissions
      ) VALUES (
        NEW.club_id,
        NEW.user_id,
        'member',
        'active',
        NOW(),
        jsonb_build_object(
          'view_tournaments', true,
          'join_tournaments', true,
          'view_members', true,
          'view_posts', true,
          'create_posts', true
        )
      );
      
      RAISE NOTICE 'Auto-added user % to club % as member after rank approval', NEW.user_id, NEW.club_id;
    ELSE
      RAISE NOTICE 'User % is already a member of club %', NEW.user_id, NEW.club_id;
    END IF;
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to call the function after rank request update
CREATE TRIGGER auto_add_member_on_rank_approval
  AFTER UPDATE ON rank_requests
  FOR EACH ROW
  WHEN (NEW.status = 'approved')
  EXECUTE FUNCTION auto_add_member_on_rank_approval();

-- Grant execute permission
GRANT EXECUTE ON FUNCTION auto_add_member_on_rank_approval() TO authenticated;

-- Add comment for documentation
COMMENT ON FUNCTION auto_add_member_on_rank_approval() IS 
'Automatically adds user to club_members when their rank request is approved. 
This ensures users become club members after successful rank verification.';

-- ============================================
-- TESTING
-- ============================================

-- To test this trigger:
-- 1. Create a rank request for a user who is not a club member
-- 2. Approve the rank request: UPDATE rank_requests SET status = 'approved' WHERE id = 'xxx'
-- 3. Verify the user is now in club_members: SELECT * FROM club_members WHERE user_id = 'xxx'

-- ============================================
-- VERIFICATION QUERY
-- ============================================

-- Check if trigger exists
SELECT 
  tgname as trigger_name,
  tgrelid::regclass as table_name,
  tgenabled as enabled,
  proname as function_name
FROM pg_trigger 
JOIN pg_proc ON pg_trigger.tgfoid = pg_proc.oid
WHERE tgname = 'auto_add_member_on_rank_approval';

-- Check if function exists
SELECT 
  proname as function_name,
  prosrc as function_source
FROM pg_proc
WHERE proname = 'auto_add_member_on_rank_approval';

COMMENT ON TRIGGER auto_add_member_on_rank_approval ON rank_requests IS
'Trigger để tự động thêm user vào club_members khi rank request được approve';
