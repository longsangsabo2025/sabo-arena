// ⚔️ SABO ARENA - Challenge System Implementation
// Implement verified-only challenges with SPA betting and handicap system

void main() async {
  print('⚔️ IMPLEMENTING CHALLENGE SYSTEM FOR SABO ARENA');
  print('=' * 60);

  await implementChallengeRules();
  await implementSPABetting();
  await implementHandicapSystem();
  await implementMatchTypes();

  print('\n✅ Challenge System Implementation completed!');
}

Future<void> implementChallengeRules() async {
  print('\n🛡️ 1. CHALLENGE ELIGIBILITY RULES');
  print('-' * 40);

  final challengeRules = {
    'eligibility_rules': [
      {
        'rule_code': 'VERIFIED_ONLY',
        'rule_name': 'Verified Players Only',
        'rule_name_vi': 'Chỉ người chơi đã xác thực',
        'description':
            'Only rank-verified players can participate in challenge matches',
        'description_vi':
            'Chỉ những người chơi đã được xác thực hạng mới có thể tham gia thách đấu',
        'is_active': true,
        'priority': 1,
      },
      {
        'rule_code': 'UNRANKED_FRIENDLY_ONLY',
        'rule_name': 'Unranked Friendly Only',
        'rule_name_vi': 'Chưa có hạng chỉ đánh giao lưu',
        'description':
            'Unranked players can only play friendly matches (no ELO/SPA stakes)',
        'description_vi':
            'Người chơi chưa đăng ký hạng chỉ có thể đánh giao lưu (không có ELO/SPA)',
        'is_active': true,
        'priority': 2,
      },
      {
        'rule_code': 'MAX_RANK_DIFFERENCE',
        'rule_name': 'Maximum Rank Difference',
        'rule_name_vi': 'Chênh lệch hạng tối đa',
        'description':
            'Maximum ±2 major ranks difference allowed for challenges',
        'description_vi': 'Chênh lệch tối đa ±2 hạng lớn cho phép thách đấu',
        'max_difference': 2,
        'is_active': true,
        'priority': 3,
      },
    ],
  };

  print('🛡️ Challenge Eligibility Rules:');
  for (var rule in challengeRules['eligibility_rules']!) {
    print('   • ${rule['rule_name']} (${rule['rule_name_vi']})');
    print('     - ${rule['description_vi']}');
  }

  print('\n📋 Challenge Flow:');
  print('   1. Check if both players are rank-verified');
  print('   2. Verify rank difference ≤ 2 major ranks');
  print('   3. Allow SPA betting and handicap application');
  print('   4. Unverified players → Friendly matches only');
}

Future<void> implementSPABetting() async {
  print('\n💰 2. SPA BETTING SYSTEM');
  print('-' * 40);

  final spaBettingConfig = {
    'bet_levels': [
      {
        'bet_amount': 100,
        'race_to': 8,
        'handicap_full': 1.0,
        'handicap_sub': 0.5,
        'description': 'Entry level betting',
        'description_vi': 'Mức cược cơ bản',
      },
      {
        'bet_amount': 200,
        'race_to': 12,
        'handicap_full': 1.5,
        'handicap_sub': 1.0,
        'description': 'Medium betting level',
        'description_vi': 'Mức cược trung bình',
      },
      {
        'bet_amount': 300,
        'race_to': 14,
        'handicap_full': 2.0,
        'handicap_sub': 1.5,
        'description': 'High betting level',
        'description_vi': 'Mức cược cao',
      },
      {
        'bet_amount': 400,
        'race_to': 16,
        'handicap_full': 2.5,
        'handicap_sub': 1.5,
        'description': 'Premium betting level',
        'description_vi': 'Mức cược cao cấp',
      },
      {
        'bet_amount': 500,
        'race_to': 18,
        'handicap_full': 3.0,
        'handicap_sub': 2.0,
        'description': 'Elite betting level',
        'description_vi': 'Mức cược tinh hoa',
      },
      {
        'bet_amount': 600,
        'race_to': 22,
        'handicap_full': 3.5,
        'handicap_sub': 2.5,
        'description': 'Master betting level',
        'description_vi': 'Mức cược bậc thầy',
      },
    ],
  };

  print('💰 SPA Betting Levels:');
  for (var bet in spaBettingConfig['bet_levels']!) {
    print('   • ${bet['bet_amount']} SPA → Race to ${bet['race_to']}');
    print(
      '     - Full Handicap: ${bet['handicap_full']} | Sub Handicap: ${bet['handicap_sub']}',
    );
    print('     - ${bet['description_vi']}');
  }

  print('\n💸 Betting Logic:');
  print('   • Winner takes all SPA points');
  print('   • Loser loses SPA points');
  print('   • Platform takes 5% commission (house edge)');
  print('   • Minimum SPA balance required to bet');
}

Future<void> implementHandicapSystem() async {
  print('\n⚖️ 3. HANDICAP SYSTEM (SABO OFFICIAL)');
  print('-' * 40);

  // Rank values for calculation (K=1, K+=2, I=3, I+=4, etc.)
  final rankValues = {
    'K': 1,
    'K+': 2,
    'I': 3,
    'I+': 4,
    'H': 5,
    'H+': 6,
    'G': 7,
    'G+': 8,
    'F': 9,
    'F+': 10,
    'E': 11,
    'E+': 12,
  };

  final handicapLogic = {
    'sub_rank_differences': [
      {
        'sub_rank_diff': 0,
        'description': 'Same rank (e.g., H vs H)',
        'description_vi': 'Cùng hạng (vd: H vs H)',
        'handicap_type': 'none',
        'example': 'H vs H → Không handicap',
      },
      {
        'sub_rank_diff': 1,
        'description': '1 sub-rank difference (e.g., K vs K+, K+ vs I)',
        'description_vi': 'Chênh lệch 1 sub-rank (vd: K vs K+, K+ vs I)',
        'handicap_type': 'handicap_05_rank',
        'example': 'K vs K+ → K được cộng +handicap_05_rank',
      },
      {
        'sub_rank_diff': 2,
        'description': '1 main rank difference (e.g., K vs I, H vs G)',
        'description_vi': 'Chênh lệch 1 main rank (vd: K vs I, H vs G)',
        'handicap_type': 'handicap_1_rank',
        'example': 'K vs I → K được cộng +handicap_1_rank',
      },
      {
        'sub_rank_diff': 3,
        'description': '1 main rank + 1 sub-rank (e.g., K vs I+, H vs G+)',
        'description_vi':
            'Chênh lệch 1 main rank + 1 sub-rank (vd: K vs I+, H vs G+)',
        'handicap_type': 'handicap_1_rank + handicap_05_rank',
        'example':
            'K vs I+ → K được cộng +(handicap_1_rank + handicap_05_rank)',
      },
      {
        'sub_rank_diff': 4,
        'description': '2 main ranks difference (e.g., K vs H, G vs E)',
        'description_vi': 'Chênh lệch 2 main rank (vd: K vs H, G vs E)',
        'handicap_type': 'handicap_1_rank × 2',
        'example': 'K vs H → K được cộng +(handicap_1_rank × 2)',
      },
    ],
  };

  print('⚖️ Handicap Logic (Dựa trên Sub-rank Difference):');
  for (var diff in handicapLogic['sub_rank_differences']!) {
    print(
      '   • Sub-rank diff ${diff['sub_rank_diff']}: ${diff['description_vi']}',
    );
    print('     - Handicap: ${diff['handicap_type']}');
    print('     - Example: ${diff['example']}');
  }

  print('\n🎯 Practical Handicap Examples:');
  print('   • 300 SPA Bet (handicap_1_rank=2.0, handicap_05_rank=1.5):');
  print('     - H vs G (sub-rank diff=2): H gets +2.0 handicap');
  print('     - K vs K+ (sub-rank diff=1): K gets +1.5 handicap');
  print('     - K vs I+ (sub-rank diff=3): K gets +3.5 handicap (2.0+1.5)');
  print('   ');
  print('   • 500 SPA Bet (handicap_1_rank=3.0, handicap_05_rank=2.0):');
  print('     - I vs H (sub-rank diff=2): I gets +3.0 handicap');
  print('     - G vs E (sub-rank diff=4): G gets +6.0 handicap (3.0×2)');
  print('   ');
  print('   • Max allowed: ±4 sub-rank difference (±2 main ranks)');
}

Future<void> implementMatchTypes() async {
  print('\n🎮 4. MATCH TYPES');
  print('-' * 40);

  final matchTypes = {
    'match_types': [
      {
        'type_code': 'CHALLENGE',
        'type_name': 'Challenge Match',
        'type_name_vi': 'Trận thách đấu',
        'description': 'Ranked match with SPA betting between verified players',
        'description_vi':
            'Trận đấu có hạng với cược SPA giữa người chơi đã xác thực',
        'requires_verification': true,
        'allows_spa_betting': true,
        'applies_handicap': true,
        'affects_elo': true,
        'affects_rank': true,
      },
      {
        'type_code': 'FRIENDLY',
        'type_name': 'Friendly Match',
        'type_name_vi': 'Trận giao lưu',
        'description': 'Casual match for unranked or practice play',
        'description_vi':
            'Trận đấu thân thiện cho người chưa có hạng hoặc luyện tập',
        'requires_verification': false,
        'allows_spa_betting': false,
        'applies_handicap': false,
        'affects_elo': false,
        'affects_rank': false,
      },
      {
        'type_code': 'TOURNAMENT',
        'type_name': 'Tournament Match',
        'type_name_vi': 'Trận giải đấu',
        'description': 'Official tournament bracket match',
        'description_vi': 'Trận đấu chính thức trong giải đấu',
        'requires_verification': true,
        'allows_spa_betting': false,
        'applies_handicap': false,
        'affects_elo': true,
        'affects_rank': true,
      },
      {
        'type_code': 'PRACTICE',
        'type_name': 'Practice Match',
        'type_name_vi': 'Trận luyện tập',
        'description': 'Training match with reduced ELO impact',
        'description_vi': 'Trận luyện tập với ảnh hưởng ELO giảm',
        'requires_verification': false,
        'allows_spa_betting': false,
        'applies_handicap': false,
        'affects_elo': true,
        'affects_rank': false,
        'elo_multiplier': 0.5,
      },
    ],
  };

  print('🎮 Match Types:');
  for (var type in matchTypes['match_types']!) {
    print('   • ${type['type_name']} (${type['type_name_vi']})');
    print('     - Verification required: ${type['requires_verification']}');
    print('     - SPA betting: ${type['allows_spa_betting']}');
    print('     - Handicap applied: ${type['applies_handicap']}');
    print('     - Affects ELO: ${type['affects_elo']}');
    print('     - Affects Rank: ${type['affects_rank']}');
    if (type.containsKey('elo_multiplier')) {
      print('     - ELO multiplier: ${type['elo_multiplier']}x');
    }
    print('');
  }
}

// Database schema for challenge system
String getChallengeSystemSQL() {
  return '''
-- ⚔️ CHALLENGE SYSTEM TABLES

-- Challenge Configuration Table
CREATE TABLE IF NOT EXISTS challenge_configurations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bet_amount INTEGER NOT NULL UNIQUE,
  race_to INTEGER NOT NULL,
  handicap_full DECIMAL(3,1) NOT NULL,
  handicap_sub DECIMAL(3,1) NOT NULL,
  description VARCHAR(100),
  description_vi VARCHAR(100),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Match Types Table
CREATE TABLE IF NOT EXISTS match_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type_code VARCHAR(20) NOT NULL UNIQUE,
  type_name VARCHAR(50) NOT NULL,
  type_name_vi VARCHAR(50) NOT NULL,
  description TEXT,
  description_vi TEXT,
  requires_verification BOOLEAN DEFAULT false,
  allows_spa_betting BOOLEAN DEFAULT false,
  applies_handicap BOOLEAN DEFAULT false,
  affects_elo BOOLEAN DEFAULT true,
  affects_rank BOOLEAN DEFAULT true,
  elo_multiplier DECIMAL(3,2) DEFAULT 1.0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Challenge Matches Table (Enhanced matches table for challenges)
CREATE TABLE IF NOT EXISTS challenge_matches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenger_id UUID NOT NULL REFERENCES users(id),
  challenged_id UUID NOT NULL REFERENCES users(id),
  match_type_id UUID NOT NULL REFERENCES match_types(id),
  challenge_config_id UUID REFERENCES challenge_configurations(id),
  spa_bet_amount INTEGER DEFAULT 0,
  handicap_applied DECIMAL(3,1) DEFAULT 0.0,
  handicap_recipient UUID REFERENCES users(id), -- Who gets the handicap
  challenger_score INTEGER DEFAULT 0,
  challenged_score INTEGER DEFAULT 0,
  winner_id UUID REFERENCES users(id),
  match_status VARCHAR(20) DEFAULT 'PENDING', -- PENDING, ACCEPTED, IN_PROGRESS, COMPLETED, CANCELLED
  game_type_id UUID REFERENCES game_types(id),
  scoring_format_id UUID REFERENCES scoring_formats(id),
  match_duration_minutes INTEGER,
  spa_payout INTEGER DEFAULT 0,
  platform_commission INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  completed_at TIMESTAMP,
  
  CONSTRAINT valid_match_status CHECK (match_status IN ('PENDING', 'ACCEPTED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
  CONSTRAINT valid_scores CHECK (challenger_score >= 0 AND challenged_score >= 0),
  CONSTRAINT valid_spa_bet CHECK (spa_bet_amount >= 0),
  CONSTRAINT different_players CHECK (challenger_id != challenged_id)
);

-- SPA Transaction History Table
CREATE TABLE IF NOT EXISTS spa_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  transaction_type VARCHAR(20) NOT NULL, -- 'BET_PLACED', 'BET_WON', 'BET_LOST', 'COMMISSION', 'REFUND'
  amount INTEGER NOT NULL, -- Can be negative for losses
  balance_before INTEGER NOT NULL,
  balance_after INTEGER NOT NULL,
  challenge_match_id UUID REFERENCES challenge_matches(id),
  tournament_id UUID REFERENCES tournaments(id),
  description TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  
  CONSTRAINT valid_transaction_type CHECK (transaction_type IN ('BET_PLACED', 'BET_WON', 'BET_LOST', 'COMMISSION', 'REFUND', 'TOURNAMENT_REWARD', 'ADMIN_ADJUSTMENT'))
);

-- Handicap Calculation Rules Table
CREATE TABLE IF NOT EXISTS handicap_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rank_difference_type VARCHAR(20) NOT NULL, -- 'SAME_RANK', 'SUB_RANK', 'ONE_MAJOR_RANK', 'TWO_MAJOR_RANKS'
  handicap_multiplier DECIMAL(3,1) NOT NULL,
  max_allowed_difference INTEGER DEFAULT 2,
  description VARCHAR(100),
  description_vi VARCHAR(100),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Insert Challenge Configurations
INSERT INTO challenge_configurations (bet_amount, race_to, handicap_full, handicap_sub, description, description_vi) VALUES
(100, 8, 1.0, 0.5, 'Entry level betting', 'Mức cược cơ bản'),
(200, 12, 1.5, 1.0, 'Medium betting level', 'Mức cược trung bình'),
(300, 14, 2.0, 1.5, 'High betting level', 'Mức cược cao'),
(400, 16, 2.5, 1.5, 'Premium betting level', 'Mức cược cao cấp'),
(500, 18, 3.0, 2.0, 'Elite betting level', 'Mức cược tinh hoa'),
(600, 22, 3.5, 2.5, 'Master betting level', 'Mức cược bậc thầy')
ON CONFLICT (bet_amount) DO NOTHING;

-- Insert Match Types
INSERT INTO match_types (type_code, type_name, type_name_vi, description, description_vi, requires_verification, allows_spa_betting, applies_handicap, affects_elo, affects_rank, elo_multiplier) VALUES
('CHALLENGE', 'Challenge Match', 'Trận thách đấu', 'Ranked match with SPA betting between verified players', 'Trận đấu có hạng với cược SPA giữa người chơi đã xác thực', true, true, true, true, true, 1.0),
('FRIENDLY', 'Friendly Match', 'Trận giao lưu', 'Casual match for unranked or practice play', 'Trận đấu thân thiện cho người chưa có hạng hoặc luyện tập', false, false, false, false, false, 0.0),
('TOURNAMENT', 'Tournament Match', 'Trận giải đấu', 'Official tournament bracket match', 'Trận đấu chính thức trong giải đấu', true, false, false, true, true, 1.0),
('PRACTICE', 'Practice Match', 'Trận luyện tập', 'Training match with reduced ELO impact', 'Trận luyện tập với ảnh hưởng ELO giảm', false, false, false, true, false, 0.5)
ON CONFLICT (type_code) DO NOTHING;

-- Insert Handicap Rules (Based on Sub-rank Differences)
INSERT INTO handicap_rules (rank_difference_type, handicap_multiplier, description, description_vi) VALUES
('SUB_RANK_0', 0.0, 'Same rank (e.g., H vs H)', 'Cùng hạng (vd: H vs H)'),
('SUB_RANK_1', 0.5, '1 sub-rank difference (e.g., K vs K+)', 'Chênh lệch 1 sub-rank (vd: K vs K+)'),
('SUB_RANK_2', 1.0, '1 main rank difference (e.g., K vs I)', 'Chênh lệch 1 main rank (vd: K vs I)'),
('SUB_RANK_3', 1.5, '1 main rank + 1 sub-rank (e.g., K vs I+)', 'Chênh lệch 1 main rank + 1 sub-rank (vd: K vs I+)'),
('SUB_RANK_4', 2.0, '2 main ranks difference (e.g., K vs H)', 'Chênh lệch 2 main rank (vd: K vs H)')
ON CONFLICT (rank_difference_type) DO NOTHING;

-- Add SPA balance to users if not exists
ALTER TABLE users ADD COLUMN IF NOT EXISTS spa_balance INTEGER DEFAULT 1000;

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_challenge_matches_challenger_id ON challenge_matches(challenger_id);
CREATE INDEX IF NOT EXISTS idx_challenge_matches_challenged_id ON challenge_matches(challenged_id);
CREATE INDEX IF NOT EXISTS idx_challenge_matches_status ON challenge_matches(match_status);
CREATE INDEX IF NOT EXISTS idx_spa_transactions_user_id ON spa_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_spa_transactions_type ON spa_transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_spa_transactions_challenge_match_id ON spa_transactions(challenge_match_id);
''';
}
