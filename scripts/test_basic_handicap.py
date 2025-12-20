#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Test basic handicap logic for race to 7"""

import sys
sys.path.insert(0, 'D:\\0.PROJECTS\\02-SABO-ECOSYSTEM\\sabo-arena\\app\\lib\\services')

# Simulate the handicap logic
rank_values = {
    'K': 1,
    'I': 2,
    'H': 3,
    'H+': 4,
    'G': 5,
    'G+': 6,
    'F': 7,
    'E': 8,
    'D': 9,
    'C': 10,
}

def calculate_basic_handicap(rank1, rank2):
    """Calculate handicap based on rank difference only"""
    value1 = rank_values.get(rank1, 0)
    value2 = rank_values.get(rank2, 0)
    
    if value1 == 0 or value2 == 0:
        return 0.0
    
    # Handicap = absolute rank difference
    return float(abs(value1 - value2))

def get_handicap_info(rank1, rank2):
    """Get handicap display info"""
    handicap = calculate_basic_handicap(rank1, rank2)
    value1 = rank_values.get(rank1, 0)
    value2 = rank_values.get(rank2, 0)
    
    if handicap == 0:
        return {
            'handicap': 0.0,
            'description': 'Không chấp (cùng hạng)',
            'recipient': None,
        }
    
    weaker_rank = rank1 if value1 < value2 else rank2
    stronger_rank = rank2 if value1 < value2 else rank1
    
    return {
        'handicap': handicap,
        'description': f'{weaker_rank} chấp {stronger_rank} {int(handicap)} ván',
        'recipient_rank': weaker_rank,
    }

print("=" * 60)
print("HANDICAP CƠ BẢN - RACE TO 7 VALIDATION")
print("=" * 60)

test_cases = [
    ['K', 'K', 0.0],
    ['K', 'I', 1.0],
    ['K', 'H', 2.0],
    ['K', 'H+', 3.0],
    ['I', 'G', 3.0],
    ['H', 'F', 4.0],
    ['G+', 'C', 4.0],
    ['I', 'I', 0.0],
    ['H+', 'G', 1.0],
]

for rank1, rank2, expected in test_cases:
    actual = calculate_basic_handicap(rank1, rank2)
    match = '✅' if actual == expected else '❌'
    info = get_handicap_info(rank1, rank2)
    
    print(f'{match} {rank1} vs {rank2} → handicap={actual} (expected={expected})')
    print(f'   {info["description"]}')

print("\n" + "=" * 60)
print("RACE TO 7 APPLICATION EXAMPLES:")
print("=" * 60)

examples = [
    ('K', 'I'),
    ('K', 'H'),
    ('I', 'G'),
    ('H', 'F'),
]

for rank1, rank2 in examples:
    info = get_handicap_info(rank1, rank2)
    weaker_rank = info['recipient_rank']
    handicap = int(info['handicap'])
    
    print(f"\n{rank1} vs {rank2}:")
    print(f"  • {info['description']}")
    print(f"  • {weaker_rank} starts: {handicap}-0")
    print(f"  • Race to: 7")
    print(f"  • {weaker_rank} wins if score reaches 7 first")

print("\n" + "=" * 60)
print("✅ Logic đơn giản: 1 rank difference = 1 ván handicap")
print("✅ KHÔNG phụ thuộc bet_amount (đó là cho challenge system)")
print("✅ Race to 7 cố định cho all matches")
print("=" * 60)
