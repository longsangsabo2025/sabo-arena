-- Verify user_blocks schema after fix
SELECT 
    'user_blocks columns' AS check_type,
    string_agg(column_name, ', ' ORDER BY ordinal_position) AS result
FROM information_schema.columns 
WHERE table_name = 'user_blocks'

UNION ALL

SELECT 
    'Foreign keys',
    string_agg(
        tc.constraint_name || ': ' || kcu.column_name || ' → ' || ccu.table_name || '.' || ccu.column_name, 
        ', '
    )
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_name='user_blocks';
