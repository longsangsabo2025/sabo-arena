-- ==========================================
-- SABO ARENA - DATA ARCHIVAL SETUP
-- Phase 8: Cost Optimization
-- ==========================================
--
-- OBJECTIVE: Set up tables and functions for data archival
-- TARGET: Reduce database size and costs by archiving old data
--
-- ==========================================

BEGIN;

-- ==========================================
-- CREATE ARCHIVE TABLES
-- ==========================================

-- Archive table for tournaments
CREATE TABLE IF NOT EXISTS tournaments_archive (
    LIKE tournaments INCLUDING ALL
);

-- Archive table for messages
CREATE TABLE IF NOT EXISTS chat_messages_archive (
    LIKE chat_messages INCLUDING ALL
);

-- Archive table for notifications
CREATE TABLE IF NOT EXISTS notifications_archive (
    LIKE notifications INCLUDING ALL
);

-- ==========================================
-- ADD ARCHIVED_AT COLUMN TO TOURNAMENTS
-- ==========================================

-- Add archived_at column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'tournaments' 
        AND column_name = 'archived_at'
    ) THEN
        ALTER TABLE tournaments ADD COLUMN archived_at TIMESTAMP WITH TIME ZONE;
    END IF;
END $$;

-- ==========================================
-- CREATE ARCHIVAL FUNCTION
-- ==========================================

-- Function to archive old tournaments
CREATE OR REPLACE FUNCTION archive_old_tournaments()
RETURNS INTEGER AS $$
DECLARE
    archived_count INTEGER;
BEGIN
    -- Move completed tournaments older than 6 months to archive
    INSERT INTO tournaments_archive
    SELECT * FROM tournaments
    WHERE status = 'completed'
    AND created_at < NOW() - INTERVAL '6 months'
    AND archived_at IS NULL;

    -- Get count
    GET DIAGNOSTICS archived_count = ROW_COUNT;

    -- Mark as archived in original table
    UPDATE tournaments
    SET archived_at = NOW()
    WHERE status = 'completed'
    AND created_at < NOW() - INTERVAL '6 months'
    AND archived_at IS NULL;

    RETURN archived_count;
END;
$$ LANGUAGE plpgsql;

-- Function to archive old messages
CREATE OR REPLACE FUNCTION archive_old_messages()
RETURNS INTEGER AS $$
DECLARE
    archived_count INTEGER;
BEGIN
    -- Move messages older than 1 year to archive
    INSERT INTO chat_messages_archive
    SELECT * FROM chat_messages
    WHERE created_at < NOW() - INTERVAL '1 year';

    -- Get count
    GET DIAGNOSTICS archived_count = ROW_COUNT;

    -- Delete from original table
    DELETE FROM chat_messages
    WHERE created_at < NOW() - INTERVAL '1 year';

    RETURN archived_count;
END;
$$ LANGUAGE plpgsql;

-- Function to archive old notifications
CREATE OR REPLACE FUNCTION archive_old_notifications()
RETURNS INTEGER AS $$
DECLARE
    archived_count INTEGER;
BEGIN
    -- Move read notifications older than 3 months to archive
    INSERT INTO notifications_archive
    SELECT * FROM notifications
    WHERE is_read = true
    AND created_at < NOW() - INTERVAL '3 months';

    -- Get count
    GET DIAGNOSTICS archived_count = ROW_COUNT;

    -- Delete from original table
    DELETE FROM notifications
    WHERE is_read = true
    AND created_at < NOW() - INTERVAL '3 months';

    RETURN archived_count;
END;
$$ LANGUAGE plpgsql;

-- ==========================================
-- CREATE INDEXES ON ARCHIVE TABLES
-- ==========================================

CREATE INDEX IF NOT EXISTS idx_tournaments_archive_created_at 
ON tournaments_archive(created_at);

CREATE INDEX IF NOT EXISTS idx_chat_messages_archive_created_at 
ON chat_messages_archive(created_at);

CREATE INDEX IF NOT EXISTS idx_notifications_archive_created_at 
ON notifications_archive(created_at);

-- ==========================================
-- CREATE SCHEDULED JOB (using pg_cron if available)
-- ==========================================

-- Note: pg_cron extension needs to be enabled by Supabase admin
-- This is a reference for when pg_cron is available:

-- Schedule weekly archival (every Sunday at 2 AM)
-- SELECT cron.schedule(
--     'archive-old-data',
--     '0 2 * * 0',  -- Every Sunday at 2 AM
--     $$
--     SELECT archive_old_tournaments();
--     SELECT archive_old_messages();
--     SELECT archive_old_notifications();
--     $$
-- );

COMMIT;

-- ==========================================
-- MANUAL EXECUTION COMMANDS
-- ==========================================

-- To manually run archival:
-- SELECT archive_old_tournaments();
-- SELECT archive_old_messages();
-- SELECT archive_old_notifications();

-- To check archival statistics:
-- SELECT 
--     (SELECT COUNT(*) FROM tournaments_archive) as archived_tournaments,
--     (SELECT COUNT(*) FROM chat_messages_archive) as archived_messages,
--     (SELECT COUNT(*) FROM notifications_archive) as archived_notifications;

