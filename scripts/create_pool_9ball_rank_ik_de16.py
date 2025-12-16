#!/usr/bin/env python3
"""
🏆 Create POOL 9 BALL RANK I-K Tournament (SABO DE16 Enhanced)
Tournament: 16 players, 29 matches with LB-B R3 & R4

Tournament Details:
- Thời gian: 10:00 Sáng, Chủ Nhật (07/12/2025)
- Địa điểm: 601A Nguyễn An Ninh, TP. Vũng Tàu
- Lệ phí: 100k / slot
- Hạng: I và K
- Số lượng: 16 VĐV
"""

import os
import psycopg2
from dotenv import load_dotenv
from datetime import datetime
import uuid

load_dotenv()

def create_tournament():
    conn = psycopg2.connect(os.getenv('SUPABASE_DB_TRANSACTION_URL'))
    cur = conn.cursor()
    
    print('🏆 Creating POOL 9 BALL RANK I-K Tournament (SABO DE16 Enhanced)\n')
    
    # 1. Get the SABO Arena club
    cur.execute("""
        SELECT id, name FROM clubs 
        WHERE name ILIKE '%sabo%' OR name ILIKE '%vung tau%' OR name ILIKE '%601%'
        LIMIT 1
    """)
    club = cur.fetchone()
    
    if not club:
        # Try getting any club
        cur.execute('SELECT id, name FROM clubs LIMIT 1')
        club = cur.fetchone()
    
    if not club:
        print('❌ No clubs found!')
        return
    
    club_id, club_name = club
    print(f'📍 Club: {club_name}')
    
    # 2. Get organizer (first user or club owner)
    cur.execute("""
        SELECT id, username FROM users 
        WHERE username ILIKE '%admin%' OR username ILIKE '%sabo%' OR username ILIKE '%long%'
        LIMIT 1
    """)
    organizer = cur.fetchone()
    
    if not organizer:
        cur.execute('SELECT id, username FROM users LIMIT 1')
        organizer = cur.fetchone()
    
    if not organizer:
        print('❌ No users found!')
        return
        
    organizer_id, organizer_name = organizer
    print(f'👤 Organizer: {organizer_name}')
    
    # 3. Create tournament
    tournament_id = str(uuid.uuid4())
    tournament_title = "POOL 9 BALL RANK I-K"
    
    # Start date: 07/12/2025 10:00 AM
    start_date = datetime(2025, 12, 7, 10, 0, 0)
    # Registration deadline: 06/12/2025 22:00 (night before)
    registration_deadline = datetime(2025, 12, 6, 22, 0, 0)
    
    description = """🎱 POOL 9 BALL RANK I-K

⏰ Thời gian: 10:00 Sáng, Chủ Nhật (07/12/2025) 
📍 Địa điểm: 601A Nguyễn An Ninh, TP. Vũng Tàu
💸 Lệ phí: 100k / slot (2 mạng, Thua trả tiền bàn 50k/1h)
👑 Hạng thi đấu: Hạng I và Hạng K
👥 Số lượng VĐV: 16

🥇 CƠ CẤU GIẢI THƯỞNG
• Champions: 1.000.000 VNĐ + 500k Voucher + Bảng vinh danh
• Runner-up: 400.000 VNĐ + 300k Voucher + Bảng vinh danh
• 3rd Place (x2): 100.000 VNĐ + 150k Voucher + Bảng vinh danh
• Top 5-8: Voucher 50k

🎯 THỂ LỆ THI ĐẤU
Thể Thức: 9 Bi | Xếp Thấp | Phá Luân Phiên | 3 Bi Về Bếp | 3 Lỗi Quốc Tế

⚖️ TỶ LỆ CHẤP
• I chấp K: 1 ván
• Đồng cơ (I-I, K-K): Chạm 6
• Tứ kết: Chạm 7
• Bán kết: Chạm 7
• Chung kết: Chạm 9

⚠️ QUY ĐỊNH TỪ BAN TỔ CHỨC
• VĐV đã đăng ký, tự ý bỏ giải sẽ không được hoàn lệ phí.
• PHÁT HIỆN GIAN LẬN HẠNG (BỊP HẠNG) SẼ BỊ LOẠI TRỰC TIẾP (Không hoàn lệ phí).
• Quyết định của BTC là quyết định cuối cùng."""

    # Prize breakdown
    prize_pool = 1600000  # 1.6M total (1M + 400k + 100k*2)
    entry_fee = 100000    # 100k

    cur.execute('''
        INSERT INTO tournaments (
            id, title, description, club_id, organizer_id,
            bracket_format, game_format, max_participants,
            start_date, registration_deadline, 
            status, entry_fee, prize_pool,
            skill_level_required, created_at, updated_at
        ) VALUES (
            %s, %s, %s, %s, %s,
            %s, %s, %s,
            %s, %s,
            %s, %s, %s,
            %s, NOW(), NOW()
        )
    ''', (
        tournament_id,
        tournament_title,
        description,
        club_id,
        organizer_id,
        'sabo_de16',      # Enhanced SABO DE16 with 29 matches
        '9-ball',         # Game format (valid: 8-ball, 9-ball, 10-ball, straight, carom, snooker, other)
        16,               # Max participants
        start_date,
        registration_deadline,
        'upcoming',       # Status
        entry_fee,        # 100k
        prize_pool,       # 1.6M
        'intermediate'    # Skill level (I-K rank)
    ))
    
    print(f'\n✅ Created tournament: {tournament_title}')
    print(f'   ID: {tournament_id}')
    print(f'   Format: sabo_de16 (Enhanced with 29 matches)')
    print(f'   Start: {start_date}')
    print(f'   Entry Fee: {entry_fee:,} VNĐ')
    print(f'   Prize Pool: {prize_pool:,} VNĐ')
    
    # Commit immediately to save the tournament
    conn.commit()
    
    print('\n' + '='*60)
    print('🎉 TOURNAMENT CREATED SUCCESSFULLY!')
    print('='*60)
    print(f'\n📋 Tournament ID: {tournament_id}')
    print(f'📍 Club: {club_name}')
    print(f'📅 Date: 07/12/2025 10:00 AM')
    print(f'🎱 Format: SABO DE16 Enhanced (29 matches)')
    print('\n🥇 CƠ CẤU GIẢI THƯỞNG:')
    print('   • Champions: 1.000.000 VNĐ + 500k Voucher + Bảng vinh danh')
    print('   • Runner-up: 400.000 VNĐ + 300k Voucher + Bảng vinh danh')
    print('   • 3rd Place (x2): 100.000 VNĐ + 150k Voucher + Bảng vinh danh')
    print('   • Top 5-8: Voucher 50k')
    print('\n📝 Next steps:')
    print('   1. Open SABO Arena app')
    print('   2. Register 16 players')
    print('   3. Start tournament to generate bracket')
    print('   4. Bracket will have: WB + LB-A + LB-B (with R3 & R4) + SABO Finals')
    
    cur.close()
    conn.close()
    
    return tournament_id

if __name__ == '__main__':
    try:
        tournament_id = create_tournament()
        print(f'\n✅ Done! Tournament ID: {tournament_id}')
    except Exception as e:
        print(f'\n❌ ERROR: {e}')
        import traceback
        traceback.print_exc()
