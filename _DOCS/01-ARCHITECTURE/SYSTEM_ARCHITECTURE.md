# 🏗️ SABO Arena - System Architecture

*Tài liệu kiến trúc hệ thống SABO Arena Mobile App*

---

## 📊 Tổng Quan Hệ Thống

```
┌─────────────────────────────────────────────────────────────────┐
│                     SABO ARENA MOBILE APP                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │  Flutter UI  │  │   Services   │  │    Models    │           │
│  │   Screens    │◄─┤   Business   │◄─┤    Data      │           │
│  │   Widgets    │  │    Logic     │  │   Classes    │           │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
│         │                 │                  │                   │
│         └─────────────────┼──────────────────┘                   │
│                           │                                      │
│                    ┌──────▼──────┐                               │
│                    │  Supabase   │                               │
│                    │   Client    │                               │
│                    └──────┬──────┘                               │
│                           │                                      │
└───────────────────────────┼──────────────────────────────────────┘
                            │
                    ┌───────▼───────┐
                    │   SUPABASE    │
                    │   BACKEND     │
                    ├───────────────┤
                    │ • PostgreSQL  │
                    │ • Auth        │
                    │ • Realtime    │
                    │ • Storage     │
                    │ • Edge Func   │
                    └───────────────┘
```

---

## 📁 Project Structure

```
lib/
├── 🎯 core/                     # Core business logic
│   ├── interfaces/              # Service interfaces
│   │   ├── bracket_service.dart
│   │   └── tournament_service.dart
│   └── factories/               # Factory patterns
│       └── bracket_service_factory.dart
│
├── 🔧 services/                 # Business services
│   ├── tournament/              # Tournament system
│   │   ├── bracket_services/    # All bracket types
│   │   ├── tournament_service.dart
│   │   └── elo_service.dart
│   ├── auth/                    # Authentication
│   ├── payment/                 # Payment processing
│   ├── notification/            # Push notifications
│   ├── chat/                    # Messaging
│   └── analytics/               # App analytics
│
├── 📦 models/                   # Data models
│   ├── tournament.dart
│   ├── user.dart
│   ├── club.dart
│   ├── match.dart
│   └── voucher.dart
│
├── 📱 screens/                  # UI Screens
│   ├── home/                    # Home & Feed
│   ├── tournament/              # Tournament views
│   ├── profile/                 # User profile
│   ├── club/                    # Club management
│   ├── challenge/               # Challenges
│   └── settings/                # App settings
│
├── 🎨 widgets/                  # Reusable widgets
│   ├── common/                  # Shared widgets
│   ├── tournament/              # Tournament widgets
│   ├── user/                    # User widgets
│   └── bracket/                 # Bracket widgets
│
└── 🛠️ utils/                    # Utilities
    ├── constants.dart
    ├── helpers.dart
    └── extensions.dart
```

---

## 🏆 Tournament System Architecture

### Factory Pattern

```dart
// Unified interface for all tournament types
abstract class BracketService {
  Future<BracketResult> processMatch(MatchData data);
  Future<List<Match>> getMatches(String tournamentId);
  Future<void> advanceWinner(String matchId, String winnerId);
}

// Factory creates appropriate service
class BracketServiceFactory {
  BracketService createService(String tournamentType) {
    switch (tournamentType) {
      case 'Single Elimination':
        return SingleEliminationService();
      case 'Double Elimination':
        return DoubleEliminationService();
      case 'SABO DE16':
        return SaboDE16Service();
      case 'SABO DE24':
        return SaboDE24Service();
      case 'SABO DE32':
        return SaboDE32Service();
      // ... more types
    }
  }
}
```

### 8 Tournament Formats

| Format | Players | Description |
|--------|---------|-------------|
| Single Elimination | Any | Classic knockout |
| Double Elimination | Any | Winners & Losers brackets |
| SABO DE16 | 16 | Custom double elim |
| SABO DE24 | 24 | Custom with groups |
| SABO DE32 | 32 | Custom double elim |
| Round Robin | Any | Everyone vs everyone |
| Swiss System | Any | Optimized pairing |
| Winner Takes All | 2 | Single match |

---

## 📊 ELO Ranking System

### Position-Based Rewards

| Position | ELO Reward |
|----------|------------|
| 1st | +75 |
| 2nd | +50 |
| 3rd | +35 |
| 4th | +25 |
| 5-8th | +15 |
| 9-16th | +10 |

### Calculation Flow

```
Match Complete → Winner Detection → ELO Calculation → Profile Update
                       ↓
              Tournament Complete
                       ↓
              Position Rewards Applied
```

---

## 🔐 Authentication Flow

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   Client    │────▶│   Supabase   │────▶│   Profile   │
│   Sign In   │     │     Auth     │     │   Created   │
└─────────────┘     └──────────────┘     └─────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│  Supported Providers:               │
│  • Email/Password                   │
│  • Phone OTP                        │
│  • Google Sign-In                   │
│  • Facebook Login                   │
│  • Apple Sign-In (iOS)              │
└─────────────────────────────────────┘
```

---

## 🗄️ Database Schema Overview

### Core Tables

| Table | Description |
|-------|-------------|
| `users` | User profiles |
| `clubs` | Club information |
| `tournaments` | Tournament metadata |
| `tournament_participants` | Player registrations |
| `matches` | Match data & scores |
| `vouchers` | Voucher/rewards |
| `posts` | Social feed |
| `challenges` | 1v1 challenges |
| `notifications` | Push notifications |

### Relationships

```
users ──┬── club_members ── clubs
        ├── tournament_participants ── tournaments ── matches
        ├── vouchers
        ├── posts
        ├── challenges (challenger/challenged)
        └── notifications
```

---

## 🔄 Real-time Features

### Supabase Subscriptions

```dart
// Tournament updates
supabase.channel('tournament-${id}')
  .onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'matches',
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'tournament_id',
      value: id,
    ),
    callback: (payload) => _handleMatchUpdate(payload),
  )
  .subscribe();
```

### Events Subscribed:
- Match score updates
- Tournament advancement
- Chat messages
- Notifications
- Profile changes

---

## 📱 Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Android | ✅ Production | Play Store |
| iOS | ✅ Production | App Store |
| iPad | ✅ Optimized | Tablet layout |
| Web | 🔧 Beta | Flutter Web |

---

## 🔧 Key Services

### UniversalMatchProgressionService
- Handles all match advancement logic
- Works across all tournament types
- Ensures data consistency

### AutoWinnerDetectionService
- Automatically detects tournament completion
- Triggers reward distribution
- Updates rankings

### NotificationService
- Push notifications (FCM)
- In-app notifications
- Email notifications (optional)

---

## 📚 Related Documentation

- [Flutter Project Structure](./FLUTTER_PROJECT_STRUCTURE.md)
- [Coding Guidelines](./CODING_GUIDELINES_SPA_UPDATES.md)
- [Single Source of Truth](./SINGLE_SOURCE_OF_TRUTH_IMPLEMENTATION.md)
- [SPA Safety System](./SPA_SAFETY_SYSTEM_README.md)

---

*Last Updated: November 2025*
