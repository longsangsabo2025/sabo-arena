-- ============================================================================
-- Migration: Fix Direct Messages RLS Policies
-- Description: Allow users to create direct message rooms (type='direct')
-- Date: 2025-01-14
-- ============================================================================

-- Make club_id nullable for direct messages
ALTER TABLE public.chat_rooms 
  ALTER COLUMN club_id DROP NOT NULL;

-- Drop old INSERT policy
DROP POLICY IF EXISTS "Club members can create chat rooms" ON public.chat_rooms;

-- Create new INSERT policy that allows both club rooms and direct messages
CREATE POLICY "Users can create chat rooms"
    ON public.chat_rooms
    FOR INSERT
    WITH CHECK (
        -- Allow direct messages (type='direct' with no club_id)
        (type = 'direct' AND club_id IS NULL AND created_by = auth.uid())
        OR
        -- Allow club chat rooms for club members
        (
            club_id IS NOT NULL
            AND EXISTS (
                SELECT 1 FROM public.club_members
                WHERE club_members.club_id = chat_rooms.club_id
                AND club_members.user_id = auth.uid()
                AND club_members.status = 'active'
            )
        )
    );

-- Add index for type column to improve query performance
CREATE INDEX IF NOT EXISTS idx_chat_rooms_type ON public.chat_rooms(type);

-- Update SELECT policy to include direct messages
DROP POLICY IF EXISTS "Users can view their chat rooms" ON public.chat_rooms;

CREATE POLICY "Users can view their chat rooms"
    ON public.chat_rooms
    FOR SELECT
    USING (
        -- Can view rooms where user is a member
        EXISTS (
            SELECT 1 FROM public.chat_room_members
            WHERE chat_room_members.room_id = chat_rooms.id
            AND chat_room_members.user_id = auth.uid()
        )
        OR
        -- Can view public club rooms (if is_active column exists)
        (NOT is_private AND club_id IS NOT NULL)
        OR
        -- Can view direct messages they created
        (type = 'direct' AND created_by = auth.uid())
    );

-- Update chat_room_members INSERT policy for direct messages
DROP POLICY IF EXISTS "Users can join public rooms" ON public.chat_room_members;

CREATE POLICY "Users can join rooms"
    ON public.chat_room_members
    FOR INSERT
    WITH CHECK (
        -- Can add self to direct messages created by self
        (
            user_id = auth.uid()
            AND EXISTS (
                SELECT 1 FROM public.chat_rooms
                WHERE chat_rooms.id = chat_room_members.room_id
                AND chat_rooms.type = 'direct'
                AND chat_rooms.created_by = auth.uid()
            )
        )
        OR
        -- Can add others to direct messages created by self
        (
            EXISTS (
                SELECT 1 FROM public.chat_rooms
                WHERE chat_rooms.id = chat_room_members.room_id
                AND chat_rooms.type = 'direct'
                AND chat_rooms.created_by = auth.uid()
            )
        )
        OR
        -- Can join public club rooms
        (
            user_id = auth.uid()
            AND EXISTS (
                SELECT 1 FROM public.chat_rooms
                WHERE chat_rooms.id = chat_room_members.room_id
                AND chat_rooms.club_id IS NOT NULL
                AND (NOT chat_rooms.is_private OR chat_rooms.created_by = auth.uid())
            )
        )
    );

-- Add comment explaining the schema
COMMENT ON COLUMN public.chat_rooms.club_id IS 'Club ID for club chat rooms. NULL for direct messages (type=direct).';
COMMENT ON COLUMN public.chat_rooms.type IS 'Chat room type: "general" for club chats, "direct" for 1-1 messages.';
