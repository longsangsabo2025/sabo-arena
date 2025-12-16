# 📊 Analytics Integration - SABO Arena

## ✅ Integrated Features

- ✅ Analytics service initialized on app startup
- ✅ Connected to unified analytics database
- ✅ Product identifier: `sabo-arena`

## 📖 Usage

### Access Analytics Service

```dart
import './services/analytics_service.dart';

final analytics = AnalyticsService();
```

### Manual Event Tracking

**Track Page/Screen Views:**

```dart
// Track screen navigation
analytics.trackPageView('tournament_list', pageTitle: 'Danh sách giải đấu');
analytics.trackPageView('tournament_detail', pageTitle: 'Chi tiết giải đấu');
analytics.trackPageView('profile', pageTitle: 'Hồ sơ người chơi');
```

**Track Tournament Events:**

```dart
// Tournament creation
analytics.trackTournamentEvent(
  'tournament_create',
  tournamentType: 'single_elimination',
  playerCount: 32,
);

// Tournament registration
analytics.trackTournamentEvent(
  'tournament_register',
  tournamentId: tournamentId,
  playerCount: 1,
);

// Tournament start
analytics.trackTournamentEvent(
  'tournament_start',
  tournamentId: tournamentId,
  tournamentType: 'single_elimination',
  playerCount: 32,
);
```

**Track Match Events:**

```dart
// Match start
analytics.trackMatchEvent(
  'match_start',
  matchId: matchId,
  player1: player1Name,
  player2: player2Name,
);

// Match complete
analytics.trackMatchEvent(
  'match_complete',
  matchId: matchId,
  player1: player1Name,
  player2: player2Name,
  winner: winnerName,
  properties: {
    'match_duration_minutes': 15,
    'final_score': '2-1',
  },
);
```

**Track Button Clicks:**

```dart
// Button interactions
analytics.trackClick('create_tournament_button');
analytics.trackClick('join_tournament_button', properties: {
  'tournament_id': tournamentId,
});
analytics.trackClick('report_score_button');
```

**Track Form Submissions:**

```dart
// Form completions
analytics.trackFormSubmit('tournament_creation_form', properties: {
  'tournament_type': 'single_elimination',
  'player_count': 32,
});

analytics.trackFormSubmit('match_score_form', properties: {
  'match_id': matchId,
  'winner': winnerId,
});
```

**Track Conversions:**

```dart
// Tournament registration (paid)
analytics.trackConversion(
  'tournament_registration',
  value: 50000, // VND
  properties: {
    'tournament_id': tournamentId,
    'payment_method': 'vnpay',
  },
);

// Voucher redemption
analytics.trackConversion(
  'voucher_redeem',
  properties: {
    'voucher_code': voucherCode,
    'discount_amount': 10000,
  },
);
```

**Track Errors:**

```dart
// Error tracking
try {
  // Some operation
} catch (e, stackTrace) {
  analytics.trackError(
    e.toString(),
    stackTrace: stackTrace.toString(),
    properties: {
      'screen': 'tournament_detail',
      'action': 'load_matches',
    },
  );
}
```

## 🎯 Recommended Events to Track

1. **Tournament Lifecycle:**

   - `tournament_create` - New tournament created
   - `tournament_register` - Player registers for tournament
   - `tournament_start` - Tournament begins
   - `tournament_complete` - Tournament finishes
   - `tournament_cancel` - Tournament cancelled

2. **Match Events:**

   - `match_start` - Match begins
   - `match_score_report` - Score reported
   - `match_complete` - Match finishes
   - `match_dispute` - Score dispute raised

3. **User Actions:**

   - `profile_update` - User updates profile
   - `elo_view` - User views ELO ranking
   - `opponent_search` - User searches for opponents
   - `friend_invite` - User invites friend

4. **Payment & Conversions:**

   - `tournament_registration` - Paid tournament entry
   - `voucher_redeem` - Voucher usage
   - `premium_purchase` - Premium feature purchase

5. **Social Features:**
   - `share_tournament` - Tournament sharing
   - `share_profile` - Profile sharing
   - `challenge_send` - Challenge sent to player

## 📊 View Dashboard

Admin dashboard with all analytics available at: LongSang `/admin/unified-analytics`

Or query data directly:

```sql
-- SABO Arena events today
SELECT * FROM analytics_events
WHERE product_name = 'sabo-arena'
AND created_at >= CURRENT_DATE;

-- Popular tournament types
SELECT
  properties->>'tournament_type' as tournament_type,
  COUNT(*) as count
FROM analytics_events
WHERE product_name = 'sabo-arena'
AND event_name = 'tournament_create'
GROUP BY properties->>'tournament_type'
ORDER BY count DESC;

-- Average tournament size
SELECT
  AVG((properties->>'player_count')::numeric) as avg_players
FROM analytics_events
WHERE product_name = 'sabo-arena'
AND event_name = 'tournament_start';

-- Conversion rate
SELECT
  COUNT(CASE WHEN event_type = 'conversion' THEN 1 END) * 100.0 /
  COUNT(CASE WHEN event_name = 'tournament_register' THEN 1 END) as conversion_rate
FROM analytics_events
WHERE product_name = 'sabo-arena';
```

## 🔗 Supabase Connection

Using shared analytics database from LongSang:

- Database: `diexsbzqwsbpilsymnfb`
- Table: `analytics_events`
- Auto-initialization: ✅ Enabled in `main.dart`

## 🛠 Implementation Details

Analytics service is initialized in `lib/main.dart`:

```dart
// 📊 Initialize Analytics
try {
  AnalyticsService();
  debugPrint('✅ Analytics ready!');
} catch (e) {
  debugPrint('⚠️ Analytics initialization failed: $e');
}
```

Service creates session ID and anonymous ID on first use, tracks device type (mobile/tablet/desktop), and automatically handles errors without crashing the app.
