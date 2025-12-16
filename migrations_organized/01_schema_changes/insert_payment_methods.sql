-- Create sample payment methods for clubs
-- Run this in Supabase SQL Editor

-- Insert payment methods for all clubs
INSERT INTO payment_methods (id, club_id, type, bank_name, account_number, account_name, qr_code_url, is_active, is_default, created_at)
SELECT 
    gen_random_uuid() as id,
    c.id as club_id,
    'bank_transfer' as type,
    'Vietcombank' as bank_name,
    '1234567890' as account_number,
    UPPER(c.name) as account_name,
    'https://api.vietqr.io/image/970436-1234567890-compact2.jpg?accountName=' || c.name as qr_code_url,
    true as is_active,
    true as is_default,
    NOW() as created_at
FROM clubs c
WHERE NOT EXISTS (
    SELECT 1 FROM payment_methods pm 
    WHERE pm.club_id = c.id
);

-- Verify
SELECT 
    pm.id,
    c.name as club_name,
    pm.type,
    pm.bank_name,
    pm.account_number,
    pm.is_active,
    pm.is_default
FROM payment_methods pm
JOIN clubs c ON c.id = pm.club_id
ORDER BY c.name;
