// 🏆 SABO ARENA - Tournament Logic Implementation
// Implement tournament formats, seeding, and prize pool distribution based on user requirements

void main() async {
  print('🏆 IMPLEMENTING TOURNAMENT LOGIC FOR SABO ARENA');
  print('=' * 60);

  await implementTournamentFormats();
  await implementSeeding();
  await implementPrizePool();
  await implementSPAPoints();
  await implementELORewards();

  print('\n✅ Tournament Logic Implementation completed!');
}

Future<void> implementTournamentFormats() async {
  print('\n📋 1. TOURNAMENT FORMATS IMPLEMENTATION');
  print('-' * 40);

  final tournamentFormats = {
    'tournament_formats': [
      {
        'format_code': 'single_elimination',
        'format_name': 'Single Elimination',
        'format_name_vi': 'Loại trực tiếp',
        'description': 'Players are eliminated after losing one match',
        'description_vi': 'Người chơi bị loại sau khi thua một trận',
        'elimination_type': 'single',
        'bracket_type': 'standard',
        'min_players': 4,
        'max_players': 64,
        'rounds_formula': 'log2(players)',
        'is_active': true,
      },
      {
        'format_code': 'double_elimination_traditional',
        'format_name': 'Double Elimination (Traditional)',
        'format_name_vi': 'Loại kép (Truyền thống)',
        'description':
            'Players must lose twice to be eliminated, traditional bracket',
        'description_vi':
            'Người chơi phải thua hai lần mới bị loại, theo kiểu truyền thống',
        'elimination_type': 'double',
        'bracket_type': 'traditional',
        'min_players': 4,
        'max_players': 32,
        'rounds_formula': '2*log2(players)-1',
        'is_active': true,
      },
      {
        'format_code': 'double_elimination_sabo',
        'format_name': 'Double Elimination (SABO)',
        'format_name_vi': 'Loại kép (SABO)',
        'description': 'SABO style double elimination with modified bracket',
        'description_vi':
            'Loại kép theo phong cách SABO với bracket được điều chỉnh',
        'elimination_type': 'double',
        'bracket_type': 'sabo_modified',
        'min_players': 4,
        'max_players': 32,
        'rounds_formula': '2*log2(players)-1',
        'is_active': true,
      },
      {
        'format_code': 'song_to',
        'format_name': 'Song Tô',
        'format_name_vi': 'Song Tô',
        'description': 'Vietnamese traditional parallel tournament format',
        'description_vi': 'Định dạng giải đấu song song truyền thống Việt Nam',
        'elimination_type': 'parallel',
        'bracket_type': 'parallel_groups',
        'min_players': 8,
        'max_players': 64,
        'rounds_formula': 'log2(players/2)+2',
        'is_active': true,
      },
      {
        'format_code': 'winner_takes_all',
        'format_name': 'Winner Takes All',
        'format_name_vi': 'Người thắng nhận tất cả',
        'description': 'Single winner tournament with all prizes',
        'description_vi': 'Giải đấu một người thắng nhận tất cả giải thưởng',
        'elimination_type': 'single',
        'bracket_type': 'winner_only',
        'min_players': 4,
        'max_players': 32,
        'rounds_formula': 'log2(players)',
        'is_active': true,
      },
    ],
  };

  print('🏆 Tournament Formats defined:');
  for (var format in tournamentFormats['tournament_formats']!) {
    print('   • ${format['format_name']} (${format['format_name_vi']})');
    print('     - Players: ${format['min_players']}-${format['max_players']}');
    print('     - Type: ${format['elimination_type']} elimination');
  }
}

Future<void> implementSeeding() async {
  print('\n🎯 2. SEEDING SYSTEM IMPLEMENTATION');
  print('-' * 40);

  final seedingLogic = {
    'seeding_methods': [
      {
        'method_code': 'elo_based',
        'method_name': 'ELO-Based Seeding',
        'method_name_vi': 'Xếp hạt giống theo ELO',
        'description': 'Seed players based on their ELO rating',
        'description_vi': 'Xếp hạt giống người chơi dựa trên điểm ELO',
        'priority': 1,
        'is_default': true,
      },
      {
        'method_code': 'rank_based',
        'method_name': 'Rank-Based Seeding',
        'method_name_vi': 'Xếp hạt giống theo hạng',
        'description':
            'Seed players based on their skill rank (K, I, H, G, F, E)',
        'description_vi':
            'Xếp hạt giống người chơi dựa trên hạng kỹ năng (K, I, H, G, F, E)',
        'priority': 2,
        'is_default': false,
      },
      {
        'method_code': 'win_rate_based',
        'method_name': 'Win Rate-Based Seeding',
        'method_name_vi': 'Xếp hạt giống theo tỷ lệ thắng',
        'description': 'Seed players based on their win percentage',
        'description_vi':
            'Xếp hạt giống người chơi dựa trên tỷ lệ phần trăm thắng',
        'priority': 3,
        'is_default': false,
      },
      {
        'method_code': 'tournament_history',
        'method_name': 'Tournament History-Based',
        'method_name_vi': 'Xếp hạt giống theo lịch sử giải đấu',
        'description': 'Seed players based on previous tournament performance',
        'description_vi':
            'Xếp hạt giống người chơi dựa trên thành tích giải đấu trước',
        'priority': 4,
        'is_default': false,
      },
    ],
  };

  print('🎲 Seeding Methods:');
  for (var method in seedingLogic['seeding_methods']!) {
    print('   • ${method['method_name']} (${method['method_name_vi']})');
    print(
      '     - Priority: ${method['priority']} ${method['is_default'] ? '(Default)' : ''}',
    );
  }

  print('\n📊 Seeding Algorithm:');
  print('   1. Sort players by selected seeding method (ELO by default)');
  print('   2. Assign seed numbers: #1 (highest) to #N (lowest)');
  print('   3. Place seeds in bracket to avoid early strong matchups');
  print('   4. #1 vs #N, #2 vs #(N-1), etc. in later rounds');
}

Future<void> implementPrizePool() async {
  print('\n💰 3. PRIZE POOL DISTRIBUTION');
  print('-' * 40);

  final prizeTypes = {
    'prize_types': [
      {
        'type_code': 'CASH',
        'type_name': 'Cash Prize',
        'type_name_vi': 'Tiền thưởng',
        'description': 'Monetary reward in VND',
        'description_vi': 'Phần thưởng bằng tiền mặt (VND)',
        'is_divisible': true,
        'currency': 'VND',
      },
      {
        'type_code': 'SPA_POINTS',
        'type_name': 'SPA Points',
        'type_name_vi': 'Điểm SPA',
        'description': 'Club loyalty points for rewards exchange',
        'description_vi': 'Điểm thưởng của club dùng để đổi thưởng',
        'is_divisible': true,
        'currency': 'SPA',
      },
      {
        'type_code': 'TROPHY',
        'type_name': 'Trophy',
        'type_name_vi': 'Cúp',
        'description': 'Physical trophy reward',
        'description_vi': 'Phần thưởng cúp vật lý',
        'is_divisible': false,
        'currency': null,
      },
      {
        'type_code': 'FLAG',
        'type_name': 'Flag',
        'type_name_vi': 'Cờ',
        'description': 'Championship flag reward',
        'description_vi': 'Phần thưởng cờ vô địch',
        'is_divisible': false,
        'currency': null,
      },
      {
        'type_code': 'MEDAL',
        'type_name': 'Medal',
        'type_name_vi': 'Huy chương',
        'description': 'Medal reward (Gold/Silver/Bronze)',
        'description_vi': 'Phần thưởng huy chương (Vàng/Bạc/Đồng)',
        'is_divisible': false,
        'currency': null,
      },
    ],
  };

  final distributionTemplates = {
    'distribution_templates': [
      {
        'template_code': 'winner_only',
        'template_name': 'Winner Takes All',
        'template_name_vi': 'Người thắng nhận tất cả',
        'distribution': [
          {
            'position': 1,
            'percentage': 100.0,
            'description': 'Champion takes everything',
          },
        ],
      },
      {
        'template_code': 'top_3',
        'template_name': 'Top 3 Distribution',
        'template_name_vi': 'Phân chia Top 3',
        'distribution': [
          {'position': 1, 'percentage': 60.0, 'description': 'Champion'},
          {'position': 2, 'percentage': 25.0, 'description': 'Runner-up'},
          {'position': 3, 'percentage': 15.0, 'description': 'Third place'},
        ],
      },
      {
        'template_code': 'top_4',
        'template_name': 'Đồng hạng 3',
        'template_name_vi': 'Đồng hạng 3',
        'distribution': [
          {'position': 1, 'percentage': 40.0, 'description': 'Champion'},
          {'position': 2, 'percentage': 30.0, 'description': 'Runner-up'},
          {'position': 3, 'percentage': 15.0, 'description': 'Third place (tied)'},
          {'position': 3, 'percentage': 15.0, 'description': 'Third place (tied)'},
        ],
      },
      {
        'template_code': 'flat_distribution',
        'template_name': 'Equal Distribution',
        'template_name_vi': 'Phân chia đều',
        'distribution': [
          {'position': 1, 'percentage': 25.0, 'description': 'Champion'},
          {'position': 2, 'percentage': 25.0, 'description': 'Runner-up'},
          {'position': 3, 'percentage': 25.0, 'description': 'Third place'},
          {'position': 4, 'percentage': 25.0, 'description': 'Fourth place'},
        ],
      },
    ],
  };

  print('🎁 Prize Types:');
  for (var prize in prizeTypes['prize_types']!) {
    print('   • ${prize['type_name']} (${prize['type_name_vi']})');
    print('     - Divisible: ${prize['is_divisible']}');
  }

  print('\n📊 Distribution Templates:');
  for (var template in distributionTemplates['distribution_templates']!) {
    print(
      '   • ${template['template_name']} (${template['template_name_vi']})',
    );
    for (var dist in template['distribution']) {
      print('     - Position ${dist['position']}: ${dist['percentage']}%');
    }
  }
}

Future<void> implementSPAPoints() async {
  print('\n⭐ 4. SPA POINTS SYSTEM');
  print('-' * 40);

  final spaPointsLogic = {
    'participation_rewards': [
      {'min_players': 4, 'max_players': 7, 'base_points': 50},
      {'min_players': 8, 'max_players': 15, 'base_points': 75},
      {'min_players': 16, 'max_players': 31, 'base_points': 100},
      {'min_players': 32, 'max_players': 64, 'base_points': 150},
    ],
    'position_multipliers': [
      {'position': 1, 'multiplier': 3.0, 'description': 'Champion'},
      {'position': 2, 'multiplier': 2.5, 'description': 'Runner-up'},
      {'position': 3, 'multiplier': 2.0, 'description': 'Third place'},
      {'position': 4, 'multiplier': 1.8, 'description': 'Fourth place'},
      {
        'position_range': '5-8',
        'multiplier': 1.5,
        'description': 'Quarter-finals',
      },
      {
        'position_range': '9-16',
        'multiplier': 1.2,
        'description': 'Round of 16',
      },
      {
        'position_range': '17+',
        'multiplier': 1.0,
        'description': 'Participation',
      },
    ],
  };

  print('⭐ SPA Points Calculation:');
  print('   Base Points (by tournament size):');
  for (var reward in spaPointsLogic['participation_rewards']!) {
    print(
      '     - ${reward['min_players']}-${reward['max_players']} players: ${reward['base_points']} points',
    );
  }

  print('\n   Position Multipliers:');
  for (var multiplier in spaPointsLogic['position_multipliers']!) {
    if (multiplier.containsKey('position')) {
      print(
        '     - Position ${multiplier['position']}: ${multiplier['multiplier']}x (${multiplier['description']})',
      );
    } else {
      print(
        '     - Position ${multiplier['position_range']}: ${multiplier['multiplier']}x (${multiplier['description']})',
      );
    }
  }

  print('\n   Formula: Final SPA Points = Base Points × Position Multiplier');
}

Future<void> implementELORewards() async {
  print('\n🎯 5. ELO TOURNAMENT REWARDS');
  print('-' * 40);

  final eloRewards = {
    'tournament_elo_rewards': [
      {
        'position': 1,
        'elo_points': 75,
        'description': 'Champion - Maximum reward',
      },
      {
        'position': 2,
        'elo_points': 60,
        'description': 'Runner-up - Excellent performance',
      },
      {
        'position': 3,
        'elo_points': 45,
        'description': 'Third place (tied) - Strong showing',
      },
      {
        'position_range': '5-8',
        'elo_points': 30,
        'description': 'Quarter-finals - Solid play',
      },
      {
        'position_range': '9-16',
        'elo_points': 20,
        'description': 'Round of 16 - Respectable',
      },
      {
        'position_range': '17-32',
        'elo_points': 15,
        'description': 'First round+ - Participation',
      },
      {
        'position_range': '33+',
        'elo_points': 10,
        'description': 'Early exit - Minimum reward',
      },
    ],
  };

  print('🏆 ELO Tournament Rewards (10-75 points):');
  for (var reward in eloRewards['tournament_elo_rewards']!) {
    if (reward.containsKey('position')) {
      print(
        '   • Position ${reward['position']}: +${reward['elo_points']} ELO (${reward['description']})',
      );
    } else {
      print(
        '   • Position ${reward['position_range']}: +${reward['elo_points']} ELO (${reward['description']})',
      );
    }
  }

  print('\n📈 Additional ELO Modifiers:');
  print('   • Tournament size bonus: +5 ELO for 32+ player tournaments');
  print('   • Upset bonus: +10 ELO for beating higher-ranked opponent');
  print(
    '   • Perfect run bonus: +5 ELO for winning without losing a match (single elim)',
  );
  print(
    '   • Streak bonus: +3 ELO for 3+ consecutive tournament top-3 finishes',
  );
}

// Database schema for tournament logic
String getTournamentLogicSQL() {
  return '''
-- 🏆 TOURNAMENT LOGIC TABLES

-- Tournament Formats Table
CREATE TABLE IF NOT EXISTS tournament_formats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  format_code VARCHAR(30) NOT NULL UNIQUE,
  format_name VARCHAR(100) NOT NULL,
  format_name_vi VARCHAR(100) NOT NULL,
  description TEXT,
  description_vi TEXT,
  elimination_type VARCHAR(20) NOT NULL, -- 'single', 'double', 'parallel'
  bracket_type VARCHAR(30) NOT NULL, -- 'standard', 'traditional', 'sabo_modified', 'parallel_groups'
  min_players INTEGER NOT NULL,
  max_players INTEGER NOT NULL,
  rounds_formula VARCHAR(50) NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Prize Pool Configuration Table
CREATE TABLE IF NOT EXISTS prize_pools (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id UUID NOT NULL REFERENCES tournaments(id),
  prize_type VARCHAR(20) NOT NULL, -- 'CASH', 'SPA_POINTS', 'TROPHY', 'FLAG', 'MEDAL'
  total_amount DECIMAL(12,2),
  distribution_template VARCHAR(30) NOT NULL,
  custom_distribution JSONB, -- For custom percentage distributions
  created_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Prize Distribution Table
CREATE TABLE IF NOT EXISTS prize_distributions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prize_pool_id UUID NOT NULL REFERENCES prize_pools(id),
  position INTEGER NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  percentage DECIMAL(5,2) NOT NULL,
  is_awarded BOOLEAN DEFAULT false,
  awarded_to UUID REFERENCES users(id),
  awarded_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

-- SPA Points Rewards Table
CREATE TABLE IF NOT EXISTS spa_points_rewards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  tournament_id UUID NOT NULL REFERENCES tournaments(id),
  base_points INTEGER NOT NULL,
  position_multiplier DECIMAL(3,2) NOT NULL,
  final_points INTEGER NOT NULL,
  position INTEGER NOT NULL,
  reason VARCHAR(100) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Tournament ELO Rewards Table
CREATE TABLE IF NOT EXISTS tournament_elo_rewards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  tournament_id UUID NOT NULL REFERENCES tournaments(id),
  base_elo_reward INTEGER NOT NULL,
  bonus_elo INTEGER DEFAULT 0,
  total_elo_reward INTEGER NOT NULL,
  position INTEGER NOT NULL,
  reason TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Insert Tournament Formats
INSERT INTO tournament_formats (format_code, format_name, format_name_vi, description, description_vi, elimination_type, bracket_type, min_players, max_players, rounds_formula) VALUES
('single_elimination', 'Single Elimination', 'Loại trực tiếp', 'Players are eliminated after losing one match', 'Người chơi bị loại sau khi thua một trận', 'single', 'standard', 4, 64, 'log2(players)'),
('double_elimination_traditional', 'Double Elimination (Traditional)', 'Loại kép (Truyền thống)', 'Players must lose twice to be eliminated, traditional bracket', 'Người chơi phải thua hai lần mới bị loại, theo kiểu truyền thống', 'double', 'traditional', 4, 32, '2*log2(players)-1'),
('double_elimination_sabo', 'Double Elimination (SABO)', 'Loại kép (SABO)', 'SABO style double elimination with modified bracket', 'Loại kép theo phong cách SABO với bracket được điều chỉnh', 'double', 'sabo_modified', 4, 32, '2*log2(players)-1'),
('song_to', 'Song Tô', 'Song Tô', 'Vietnamese traditional parallel tournament format', 'Định dạng giải đấu song song truyền thống Việt Nam', 'parallel', 'parallel_groups', 8, 64, 'log2(players/2)+2'),
('winner_takes_all', 'Winner Takes All', 'Người thắng nhận tất cả', 'Single winner tournament with all prizes', 'Giải đấu một người thắng nhận tất cả giải thưởng', 'single', 'winner_only', 4, 32, 'log2(players)')
ON CONFLICT (format_code) DO NOTHING;

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_prize_pools_tournament_id ON prize_pools(tournament_id);
CREATE INDEX IF NOT EXISTS idx_prize_distributions_prize_pool_id ON prize_distributions(prize_pool_id);
CREATE INDEX IF NOT EXISTS idx_spa_points_rewards_user_id ON spa_points_rewards(user_id);
CREATE INDEX IF NOT EXISTS idx_spa_points_rewards_tournament_id ON spa_points_rewards(tournament_id);
CREATE INDEX IF NOT EXISTS idx_tournament_elo_rewards_user_id ON tournament_elo_rewards(user_id);
CREATE INDEX IF NOT EXISTS idx_tournament_elo_rewards_tournament_id ON tournament_elo_rewards(tournament_id);
''';
}
