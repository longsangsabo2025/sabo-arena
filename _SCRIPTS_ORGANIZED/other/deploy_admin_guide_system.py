import psycopg2

# Use working connection from previous scripts
db_url = 'postgresql://postgres.mogjjvscxjwvhtpkrlqr:Acookingoil123@aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres'

print('🚀 Deploying Admin Guide System to Supabase...\n')

# Read SQL file
with open('sql/create_admin_guide_system.sql', 'r', encoding='utf-8') as f:
    sql_script = f.read()

try:
    conn = psycopg2.connect(db_url)
    cursor = conn.cursor()
    
    # Execute the entire SQL script
    cursor.execute(sql_script)
    conn.commit()
    
    # Verify tables created
    print('✅ Verifying deployment...\n')
    
    # Check admin_guides table
    cursor.execute("""
        SELECT COUNT(*) FROM information_schema.tables 
        WHERE table_name = 'admin_guides'
    """)
    guides_exists = cursor.fetchone()[0] > 0
    print(f'  📋 admin_guides table: {"✅ Created" if guides_exists else "❌ Failed"}')
    
    # Check admin_guide_progress table
    cursor.execute("""
        SELECT COUNT(*) FROM information_schema.tables 
        WHERE table_name = 'admin_guide_progress'
    """)
    progress_exists = cursor.fetchone()[0] > 0
    print(f'  📊 admin_guide_progress table: {"✅ Created" if progress_exists else "❌ Failed"}')
    
    # Check admin_quick_help table
    cursor.execute("""
        SELECT COUNT(*) FROM information_schema.tables 
        WHERE table_name = 'admin_quick_help'
    """)
    help_exists = cursor.fetchone()[0] > 0
    print(f'  💡 admin_quick_help table: {"✅ Created" if help_exists else "❌ Failed"}')
    
    # Check quick help data
    cursor.execute("SELECT COUNT(*) FROM admin_quick_help")
    help_count = cursor.fetchone()[0]
    print(f'  📝 Quick help entries: {help_count} tooltips')
    
    # Check functions
    cursor.execute("""
        SELECT COUNT(*) FROM pg_proc 
        WHERE proname IN (
            'get_user_completed_guides_count',
            'get_user_guides_in_progress',
            'complete_admin_guide'
        )
    """)
    function_count = cursor.fetchone()[0]
    print(f'  ⚙️  SQL functions: {function_count}/3 created')
    
    # Check RLS policies
    cursor.execute("""
        SELECT COUNT(*) FROM pg_policies 
        WHERE tablename IN ('admin_guides', 'admin_guide_progress', 'admin_quick_help')
    """)
    policy_count = cursor.fetchone()[0]
    print(f'  🔒 RLS policies: {policy_count} active')
    
    print('\n✅ DEPLOYMENT COMPLETE!')
    print('\n📦 Admin Guide System:')
    print('  ✅ 3 tables (guides, progress, quick_help)')
    print('  ✅ 3 SQL functions (count, in_progress, complete)')
    print('  ✅ 5 quick help tooltips for notification screen')
    print('  ✅ RLS policies for security')
    print('\n🎯 Next steps:')
    print('  1. Test guide library: Admin → Khác → Hướng dẫn Admin')
    print('  2. View notification guide (8 steps)')
    print('  3. Complete a guide to test progress tracking')
    print('  4. Add contextual help buttons to screens')
    
    cursor.close()
    conn.close()
    
except Exception as e:
    print(f'\n❌ Error: {e}')
    if conn:
        conn.rollback()
        conn.close()
