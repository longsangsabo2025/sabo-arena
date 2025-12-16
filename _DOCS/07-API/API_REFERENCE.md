# 🔌 SABO Arena - API Reference

*API và Service documentation*

---

## 📊 Supabase API

### Base Configuration

```dart
// lib/services/supabase_service.dart
final supabase = Supabase.instance.client;

// URL: https://mogjjvscxjwvhtpkrlqr.supabase.co
// Anon Key: [from env.json]
```

---

## 👤 User API

### Get User Profile
```dart
final response = await supabase
  .from('users')
  .select()
  .eq('id', userId)
  .single();
```

### Update Profile
```dart
await supabase
  .from('users')
  .update({
    'display_name': newName,
    'avatar_url': newAvatarUrl,
  })
  .eq('id', userId);
```

### Get User Stats
```dart
final stats = await supabase
  .from('users')
  .select('elo_rating, total_matches, wins, losses')
  .eq('id', userId)
  .single();
```

---

## 🏆 Tournament API

### List Tournaments
```dart
final tournaments = await supabase
  .from('tournaments')
  .select('''
    *,
    club:clubs(*),
    organizer:users!organizer_id(display_name, avatar_url),
    participants:tournament_participants(count)
  ''')
  .eq('status', 'active')
  .order('start_date', ascending: true);
```

### Get Tournament Detail
```dart
final tournament = await supabase
  .from('tournaments')
  .select('''
    *,
    club:clubs(*),
    participants:tournament_participants(
      user:users(id, display_name, avatar_url, elo_rating)
    ),
    matches(*)
  ''')
  .eq('id', tournamentId)
  .single();
```

### Register for Tournament
```dart
await supabase
  .from('tournament_participants')
  .insert({
    'tournament_id': tournamentId,
    'user_id': userId,
    'status': 'registered',
  });
```

### Get Matches
```dart
final matches = await supabase
  .from('matches')
  .select('''
    *,
    player1:users!player1_id(id, display_name, avatar_url),
    player2:users!player2_id(id, display_name, avatar_url)
  ''')
  .eq('tournament_id', tournamentId)
  .order('round')
  .order('position');
```

### Update Match Score
```dart
await supabase
  .from('matches')
  .update({
    'player1_score': score1,
    'player2_score': score2,
    'winner_id': winnerId,
    'status': 'completed',
    'completed_at': DateTime.now().toIso8601String(),
  })
  .eq('id', matchId);
```

---

## 🏢 Club API

### Get Club
```dart
final club = await supabase
  .from('clubs')
  .select('''
    *,
    owner:users!owner_id(display_name, avatar_url),
    members:club_members(
      user:users(id, display_name, avatar_url)
    )
  ''')
  .eq('id', clubId)
  .single();
```

### Get Club Tournaments
```dart
final tournaments = await supabase
  .from('tournaments')
  .select('*, participants:tournament_participants(count)')
  .eq('club_id', clubId)
  .order('created_at', ascending: false);
```

### Join Club
```dart
await supabase
  .from('club_members')
  .insert({
    'club_id': clubId,
    'user_id': userId,
    'role': 'member',
  });
```

---

## ⚔️ Challenge API

### Create Challenge
```dart
await supabase
  .from('challenges')
  .insert({
    'challenger_id': currentUserId,
    'challenged_id': targetUserId,
    'club_id': clubId,
    'elo_stake': eloStake,
    'status': 'pending',
  });
```

### Get Pending Challenges
```dart
final challenges = await supabase
  .from('challenges')
  .select('''
    *,
    challenger:users!challenger_id(display_name, avatar_url, elo_rating),
    challenged:users!challenged_id(display_name, avatar_url, elo_rating)
  ''')
  .or('challenger_id.eq.$userId,challenged_id.eq.$userId')
  .eq('status', 'pending');
```

### Accept Challenge
```dart
await supabase
  .from('challenges')
  .update({
    'status': 'accepted',
    'responded_at': DateTime.now().toIso8601String(),
  })
  .eq('id', challengeId);
```

---

## 🎟️ Voucher API

### Get User Vouchers
```dart
final vouchers = await supabase
  .from('vouchers')
  .select('*, club:clubs(name, logo_url)')
  .eq('user_id', userId)
  .eq('is_used', false)
  .gt('expires_at', DateTime.now().toIso8601String());
```

### Redeem Voucher
```dart
await supabase
  .from('vouchers')
  .update({
    'is_used': true,
    'used_at': DateTime.now().toIso8601String(),
  })
  .eq('id', voucherId)
  .eq('user_id', userId);
```

---

## 📱 Posts API

### Get Feed
```dart
final posts = await supabase
  .from('posts')
  .select('''
    *,
    user:users(id, display_name, avatar_url)
  ''')
  .order('created_at', ascending: false)
  .limit(20);
```

### Create Post
```dart
await supabase
  .from('posts')
  .insert({
    'user_id': userId,
    'content': content,
    'image_urls': imageUrls,
  });
```

### Like Post
```dart
await supabase
  .from('post_likes')
  .insert({
    'post_id': postId,
    'user_id': userId,
  });
```

---

## 🔔 Notifications API

### Get Notifications
```dart
final notifications = await supabase
  .from('notifications')
  .select()
  .eq('user_id', userId)
  .order('created_at', ascending: false)
  .limit(50);
```

### Mark as Read
```dart
await supabase
  .from('notifications')
  .update({'is_read': true})
  .eq('id', notificationId);
```

---

## 🔄 Realtime Subscriptions

### Match Updates
```dart
supabase.channel('matches-$tournamentId')
  .onPostgresChanges(
    event: PostgresChangeEvent.update,
    schema: 'public',
    table: 'matches',
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'tournament_id',
      value: tournamentId,
    ),
    callback: (payload) {
      // Handle match update
      final match = Match.fromJson(payload.newRecord);
      _updateMatch(match);
    },
  )
  .subscribe();
```

### Notifications
```dart
supabase.channel('notifications-$userId')
  .onPostgresChanges(
    event: PostgresChangeEvent.insert,
    schema: 'public',
    table: 'notifications',
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'user_id',
      value: userId,
    ),
    callback: (payload) {
      _showNotification(payload.newRecord);
    },
  )
  .subscribe();
```

---

## 🔐 Authentication API

### Sign In with Email
```dart
final response = await supabase.auth.signInWithPassword(
  email: email,
  password: password,
);
```

### Sign In with Phone OTP
```dart
// Send OTP
await supabase.auth.signInWithOtp(phone: phoneNumber);

// Verify OTP
final response = await supabase.auth.verifyOTP(
  phone: phoneNumber,
  token: otpCode,
  type: OtpType.sms,
);
```

### Social Sign In
```dart
// Google
await supabase.auth.signInWithOAuth(OAuthProvider.google);

// Facebook
await supabase.auth.signInWithOAuth(OAuthProvider.facebook);

// Apple
await supabase.auth.signInWithOAuth(OAuthProvider.apple);
```

### Sign Out
```dart
await supabase.auth.signOut();
```

---

## 📊 Analytics Events

```dart
// Log custom event
await FirebaseAnalytics.instance.logEvent(
  name: 'tournament_joined',
  parameters: {
    'tournament_id': tournamentId,
    'tournament_type': type,
  },
);
```

---

*Last Updated: November 2025*
