-- Kiểm tra và thêm cột evidence_urls vào rank_requests nếu chưa có
-- Chạy script này trong Supabase SQL Editor

-- Kiểm tra xem cột evidence_urls đã tồn tại chưa
DO $$
BEGIN
    -- Thử thêm cột evidence_urls nếu chưa có
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'rank_requests' 
        AND column_name = 'evidence_urls'
    ) THEN
        ALTER TABLE public.rank_requests 
        ADD COLUMN evidence_urls TEXT[];
        
        RAISE NOTICE 'Đã thêm cột evidence_urls vào bảng rank_requests';
    ELSE
        RAISE NOTICE 'Cột evidence_urls đã tồn tại';
    END IF;
END $$;

-- Kiểm tra structure cuối cùng
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'rank_requests'
ORDER BY ordinal_position;
