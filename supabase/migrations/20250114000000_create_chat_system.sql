-- ============================================================================
-- Migration: Create Chat System Tables
-- Description: Creates tables for real-time messaging system
-- Date: 2025-01-14
-- ============================================================================

-- ============================================================================
-- TABLE: chat_rooms
-- Description: Store chat rooms/channels for clubs
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.chat_rooms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    type TEXT NOT NULL DEFAULT 'general',
    is_private BOOLEAN NOT NULL DEFAULT false,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_by UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for chat_rooms
CREATE INDEX IF NOT EXISTS idx_chat_rooms_club_id ON public.chat_rooms(club_id);
CREATE INDEX IF NOT EXISTS idx_chat_rooms_created_by ON public.chat_rooms(created_by);
CREATE INDEX IF NOT EXISTS idx_chat_rooms_is_active ON public.chat_rooms(is_active);
CREATE INDEX IF NOT EXISTS idx_chat_rooms_updated_at ON public.chat_rooms(updated_at DESC);

-- Trigger to auto-update updated_at
CREATE OR REPLACE FUNCTION update_chat_room_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER chat_rooms_updated_at
    BEFORE UPDATE ON public.chat_rooms
    FOR EACH ROW
    EXECUTE FUNCTION update_chat_room_updated_at();

-- ============================================================================
-- TABLE: chat_messages
-- Description: Store individual messages in chat rooms
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID NOT NULL REFERENCES public.chat_rooms(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    message_type TEXT NOT NULL DEFAULT 'text',
    reply_to UUID REFERENCES public.chat_messages(id) ON DELETE SET NULL,
    attachments JSONB,
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for chat_messages
CREATE INDEX IF NOT EXISTS idx_chat_messages_room_id ON public.chat_messages(room_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender_id ON public.chat_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON public.chat_messages(room_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_messages_reply_to ON public.chat_messages(reply_to);
CREATE INDEX IF NOT EXISTS idx_chat_messages_is_deleted ON public.chat_messages(is_deleted);

-- Trigger to auto-update updated_at
CREATE OR REPLACE FUNCTION update_chat_message_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER chat_messages_updated_at
    BEFORE UPDATE ON public.chat_messages
    FOR EACH ROW
    EXECUTE FUNCTION update_chat_message_updated_at();

-- ============================================================================
-- TABLE: chat_room_members
-- Description: Track users who are members of chat rooms
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.chat_room_members (
    room_id UUID NOT NULL REFERENCES public.chat_rooms(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'member',
    last_read_at TIMESTAMPTZ,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (room_id, user_id)
);

-- Indexes for chat_room_members
CREATE INDEX IF NOT EXISTS idx_chat_room_members_user_id ON public.chat_room_members(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_room_members_room_id ON public.chat_room_members(room_id);
CREATE INDEX IF NOT EXISTS idx_chat_room_members_role ON public.chat_room_members(role);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS
ALTER TABLE public.chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_room_members ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- RLS POLICIES: chat_rooms
-- ============================================================================

-- Policy: Users can view chat rooms they are members of
CREATE POLICY "Users can view their chat rooms"
    ON public.chat_rooms
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.chat_room_members
            WHERE chat_room_members.room_id = chat_rooms.id
            AND chat_room_members.user_id = auth.uid()
        )
        OR
        (NOT is_private AND is_active)
    );

-- Policy: Users can create chat rooms in clubs they are members of
CREATE POLICY "Club members can create chat rooms"
    ON public.chat_rooms
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.club_members
            WHERE club_members.club_id = chat_rooms.club_id
            AND club_members.user_id = auth.uid()
            AND club_members.status = 'active'
        )
    );

-- Policy: Room admins can update chat rooms
CREATE POLICY "Room admins can update chat rooms"
    ON public.chat_rooms
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.chat_room_members
            WHERE chat_room_members.room_id = chat_rooms.id
            AND chat_room_members.user_id = auth.uid()
            AND chat_room_members.role = 'admin'
        )
    );

-- Policy: Room admins can delete (deactivate) chat rooms
CREATE POLICY "Room admins can delete chat rooms"
    ON public.chat_rooms
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.chat_room_members
            WHERE chat_room_members.room_id = chat_rooms.id
            AND chat_room_members.user_id = auth.uid()
            AND chat_room_members.role = 'admin'
        )
    );

-- ============================================================================
-- RLS POLICIES: chat_messages
-- ============================================================================

-- Policy: Room members can view messages
CREATE POLICY "Room members can view messages"
    ON public.chat_messages
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.chat_room_members
            WHERE chat_room_members.room_id = chat_messages.room_id
            AND chat_room_members.user_id = auth.uid()
        )
    );

-- Policy: Room members can send messages
CREATE POLICY "Room members can send messages"
    ON public.chat_messages
    FOR INSERT
    WITH CHECK (
        sender_id = auth.uid()
        AND
        EXISTS (
            SELECT 1 FROM public.chat_room_members
            WHERE chat_room_members.room_id = chat_messages.room_id
            AND chat_room_members.user_id = auth.uid()
        )
    );

-- Policy: Users can update their own messages
CREATE POLICY "Users can update their own messages"
    ON public.chat_messages
    FOR UPDATE
    USING (sender_id = auth.uid())
    WITH CHECK (sender_id = auth.uid());

-- Policy: Users can delete (soft delete) their own messages
CREATE POLICY "Users can delete their own messages"
    ON public.chat_messages
    FOR UPDATE
    USING (sender_id = auth.uid())
    WITH CHECK (sender_id = auth.uid() AND is_deleted = true);

-- ============================================================================
-- RLS POLICIES: chat_room_members
-- ============================================================================

-- Policy: Users can view room members of rooms they are in
CREATE POLICY "Users can view room members"
    ON public.chat_room_members
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.chat_room_members AS crm
            WHERE crm.room_id = chat_room_members.room_id
            AND crm.user_id = auth.uid()
        )
    );

-- Policy: Users can join public rooms
CREATE POLICY "Users can join public rooms"
    ON public.chat_room_members
    FOR INSERT
    WITH CHECK (
        user_id = auth.uid()
        AND
        EXISTS (
            SELECT 1 FROM public.chat_rooms
            WHERE chat_rooms.id = chat_room_members.room_id
            AND (NOT chat_rooms.is_private OR chat_rooms.created_by = auth.uid())
        )
    );

-- Policy: Room admins can add members
CREATE POLICY "Room admins can add members"
    ON public.chat_room_members
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.chat_room_members AS crm
            WHERE crm.room_id = chat_room_members.room_id
            AND crm.user_id = auth.uid()
            AND crm.role = 'admin'
        )
    );

-- Policy: Users can update their own membership (last_read_at)
CREATE POLICY "Users can update their own membership"
    ON public.chat_room_members
    FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- Policy: Room admins can update member roles
CREATE POLICY "Room admins can update member roles"
    ON public.chat_room_members
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.chat_room_members AS crm
            WHERE crm.room_id = chat_room_members.room_id
            AND crm.user_id = auth.uid()
            AND crm.role = 'admin'
        )
    );

-- Policy: Users can leave rooms
CREATE POLICY "Users can leave rooms"
    ON public.chat_room_members
    FOR DELETE
    USING (user_id = auth.uid());

-- Policy: Room admins can remove members
CREATE POLICY "Room admins can remove members"
    ON public.chat_room_members
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.chat_room_members AS crm
            WHERE crm.room_id = chat_room_members.room_id
            AND crm.user_id = auth.uid()
            AND crm.role = 'admin'
        )
    );

-- ============================================================================
-- FOREIGN KEY CONSTRAINTS (Named for reference in chat_service.dart)
-- ============================================================================

-- Add named foreign key for chat_messages -> users (sender)
ALTER TABLE public.chat_messages
    ADD CONSTRAINT chat_messages_sender_id_fkey
    FOREIGN KEY (sender_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- Add named foreign key for chat_messages -> chat_messages (reply)
ALTER TABLE public.chat_messages
    ADD CONSTRAINT chat_messages_reply_to_fkey
    FOREIGN KEY (reply_to) REFERENCES public.chat_messages(id) ON DELETE SET NULL;

-- ============================================================================
-- ENABLE REALTIME
-- ============================================================================

-- Enable realtime for chat_messages (for instant messaging)
ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;

-- Enable realtime for chat_rooms (for room updates)
ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_rooms;

-- Enable realtime for chat_room_members (for member updates)
ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_room_members;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE public.chat_rooms IS 'Chat rooms/channels associated with clubs';
COMMENT ON TABLE public.chat_messages IS 'Individual messages sent in chat rooms';
COMMENT ON TABLE public.chat_room_members IS 'Members of chat rooms with their roles and read status';

COMMENT ON COLUMN public.chat_rooms.type IS 'Room type: general, announcement, private, etc.';
COMMENT ON COLUMN public.chat_rooms.is_private IS 'Whether room requires invitation to join';
COMMENT ON COLUMN public.chat_messages.message_type IS 'Message type: text, image, file, system, etc.';
COMMENT ON COLUMN public.chat_messages.attachments IS 'JSON array of attachment URLs';
COMMENT ON COLUMN public.chat_messages.is_deleted IS 'Soft delete flag for messages';
COMMENT ON COLUMN public.chat_room_members.role IS 'Member role: admin, moderator, member';
COMMENT ON COLUMN public.chat_room_members.last_read_at IS 'Timestamp of last message read by user';
