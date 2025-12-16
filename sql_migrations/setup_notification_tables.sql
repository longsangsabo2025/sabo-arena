-- Tạo bảng club_notifications cho thông báo đến club
CREATE TABLE IF NOT EXISTS public.club_notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    club_id TEXT NOT NULL,
    notification_type TEXT NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    data JSONB DEFAULT '{}',
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tạo bảng user_notifications cho thông báo đến user
CREATE TABLE IF NOT EXISTS public.user_notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_email TEXT NOT NULL,
    notification_type TEXT NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    data JSONB DEFAULT '{}',
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Thêm cột status vào user_vouchers nếu chưa có
ALTER TABLE public.user_vouchers 
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active';

ALTER TABLE public.user_vouchers 
ADD COLUMN IF NOT EXISTS requested_at TIMESTAMP WITH TIME ZONE;

-- Tạo index cho performance
CREATE INDEX IF NOT EXISTS idx_club_notifications_club_id ON public.club_notifications(club_id);
CREATE INDEX IF NOT EXISTS idx_club_notifications_type ON public.club_notifications(notification_type);
CREATE INDEX IF NOT EXISTS idx_club_notifications_unread ON public.club_notifications(club_id, is_read);

CREATE INDEX IF NOT EXISTS idx_user_notifications_email ON public.user_notifications(user_email);
CREATE INDEX IF NOT EXISTS idx_user_notifications_type ON public.user_notifications(notification_type);
CREATE INDEX IF NOT EXISTS idx_user_notifications_unread ON public.user_notifications(user_email, is_read);

CREATE INDEX IF NOT EXISTS idx_user_vouchers_status ON public.user_vouchers(status);

-- Tạo function để cộng SPA cho user
CREATE OR REPLACE FUNCTION add_spa_to_user(
    user_email_param TEXT,
    spa_amount INTEGER
)
RETURNS VOID AS $$
BEGIN
    -- Cộng SPA vào users table
    UPDATE users 
    SET spa_points = COALESCE(spa_points, 0) + spa_amount,
        updated_at = NOW()
    WHERE email = user_email_param;
    
    -- Nếu không tìm thấy user, không làm gì cả
    IF NOT FOUND THEN
        RAISE EXCEPTION 'User with email % not found', user_email_param;
    END IF;
END;
$$ LANGUAGE plpgsql;