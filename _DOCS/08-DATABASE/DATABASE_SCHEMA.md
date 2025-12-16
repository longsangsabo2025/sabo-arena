# 🗄️ SABO Arena - Database Schema

*Complete database schema documentation*

---

## 📊 Database Overview

**Platform:** Supabase (PostgreSQL)
**Connection:** Transaction Pooler (6543)
**Features:** RLS, Realtime, Edge Functions

---

## 📋 Core Tables

### 👤 users
User profiles and authentication data

| Column | Type | Description |
|--------|------|-------------|
| id | uuid | Primary key (Supabase Auth) |
| email | text | User email |
| phone | text | Phone number |
| display_name | text | Display name |
| avatar_url | text | Profile picture URL |
| elo_rating | int | Current ELO (default: 1000) |
| mang_rank | text | Mang ranking level |
| total_matches | int | Total matches played |
| wins | int | Total wins |
| losses | int | Total losses |
| club_id | uuid | FK to clubs |
| created_at | timestamptz | Registration date |
| updated_at | timestamptz | Last update |

### 🏢 clubs
Club/venue information

| Column | Type | Description |
|--------|------|-------------|
| id | uuid | Primary key |
| name | text | Club name |
| owner_id | uuid | FK to users |
| address | text | Physical address |
| phone | text | Contact phone |
| description | text | Club description |
| logo_url | text | Club logo |
| cover_url | text | Cover image |
| is_verified | bool | Verification status |
| created_at | timestamptz | Creation date |

### 👥 club_members
Club membership tracking

| Column | Type | Description |
|--------|------|-------------|
| id | uuid | Primary key |
| club_id | uuid | FK to clubs |
| user_id | uuid | FK to users |
| role | text | member/admin/owner |
| joined_at | timestamptz | Join date |

### 🏆 tournaments
Tournament metadata

| Column | Type | Description |
|--------|------|-------------|
| id | uuid | Primary key |
| name | text | Tournament name |
| type | text | Tournament format |
| club_id | uuid | FK to clubs |
| organizer_id | uuid | FK to users |
| status | text | draft/active/completed |
| max_participants | int | Max players |
| entry_fee | decimal | Entry fee |
| prize_pool | text | Prize description |
| start_date | timestamptz | Start date |
| end_date | timestamptz | End date |
| created_at | timestamptz | Creation date |

### 📋 tournament_participants
Player registrations

| Column | Type | Description |
|--------|------|-------------|
| id | uuid | Primary key |
| tournament_id | uuid | FK to tournaments |
| user_id | uuid | FK to users |
| seed | int | Seeding position |
| status | text | registered/confirmed/eliminated |
| final_position | int | Final standing |
| elo_reward | int | ELO points earned |
| registered_at | timestamptz | Registration date |

### ⚔️ matches
Match data and scores

| Column | Type | Description |
|--------|------|-------------|
| id | uuid | Primary key |
| tournament_id | uuid | FK to tournaments |
| round | int | Round number |
| position | int | Match position in round |
| player1_id | uuid | FK to users |
| player2_id | uuid | FK to users |
| winner_id | uuid | FK to users |
| player1_score | int | Player 1 score |
| player2_score | int | Player 2 score |
| status | text | pending/active/completed |
| bracket_type | text | winners/losers/finals |
| table_number | int | Physical table |
| scheduled_at | timestamptz | Scheduled time |
| started_at | timestamptz | Actual start |
| completed_at | timestamptz | Completion time |

### 🎟️ vouchers
Rewards and vouchers

| Column | Type | Description |
|--------|------|-------------|
| id | uuid | Primary key |
| user_id | uuid | FK to users |
| club_id | uuid | FK to clubs (optional) |
| code | text | Voucher code |
| type | text | discount/free_game/etc |
| value | decimal | Voucher value |
| description | text | Description |
| is_used | bool | Usage status |
| expires_at | timestamptz | Expiration |
| created_at | timestamptz | Creation date |

### ⚔️ challenges
1v1 challenge system

| Column | Type | Description |
|--------|------|-------------|
| id | uuid | Primary key |
| challenger_id | uuid | FK to users |
| challenged_id | uuid | FK to users |
| club_id | uuid | FK to clubs |
| status | text | pending/accepted/completed |
| elo_stake | int | ELO points at stake |
| winner_id | uuid | FK to users |
| created_at | timestamptz | Challenge date |
| responded_at | timestamptz | Response date |
| completed_at | timestamptz | Completion date |

### 📱 posts
Social feed

| Column | Type | Description |
|--------|------|-------------|
| id | uuid | Primary key |
| user_id | uuid | FK to users |
| content | text | Post content |
| image_urls | text[] | Array of images |
| likes_count | int | Like count |
| comments_count | int | Comment count |
| created_at | timestamptz | Post date |

### 🔔 notifications
Push notifications

| Column | Type | Description |
|--------|------|-------------|
| id | uuid | Primary key |
| user_id | uuid | FK to users |
| type | text | Notification type |
| title | text | Title |
| body | text | Message body |
| data | jsonb | Extra data |
| is_read | bool | Read status |
| created_at | timestamptz | Creation date |

---

## 🔐 Row Level Security (RLS)

### Key Policies

```sql
-- Users can read public profiles
CREATE POLICY "Public profiles are viewable"
ON users FOR SELECT
USING (true);

-- Users can update own profile
CREATE POLICY "Users can update own profile"
ON users FOR UPDATE
USING (auth.uid() = id);

-- Tournament participants visible to all
CREATE POLICY "Participants are viewable"
ON tournament_participants FOR SELECT
USING (true);

-- Only organizers can manage tournaments
CREATE POLICY "Organizers can manage tournaments"
ON tournaments FOR ALL
USING (auth.uid() = organizer_id);
```

---

## 📊 Key Indexes

```sql
-- Fast user lookups
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_club ON users(club_id);

-- Tournament queries
CREATE INDEX idx_tournaments_status ON tournaments(status);
CREATE INDEX idx_tournaments_club ON tournaments(club_id);

-- Match lookups
CREATE INDEX idx_matches_tournament ON matches(tournament_id);
CREATE INDEX idx_matches_players ON matches(player1_id, player2_id);
CREATE INDEX idx_matches_status ON matches(status);
```

---

## 🔄 Database Functions

### ELO Update Trigger
```sql
CREATE OR REPLACE FUNCTION update_elo_after_match()
RETURNS TRIGGER AS $$
BEGIN
  -- Update winner ELO
  -- Update loser ELO
  -- Record in elo_history
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### Tournament Completion
```sql
CREATE OR REPLACE FUNCTION complete_tournament()
RETURNS TRIGGER AS $$
BEGIN
  -- Calculate final positions
  -- Distribute rewards
  -- Update statistics
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

---

## 📁 Migrations Location

```
supabase/
├── migrations/
│   ├── 001_initial_schema.sql
│   ├── 002_add_elo_system.sql
│   ├── 003_tournament_improvements.sql
│   └── ...
└── functions/
    └── tournament_automation.sql
```

---

## 🔗 Entity Relationships

```
users ←─┬─→ clubs (via club_members)
        ├─→ tournaments (as organizer)
        ├─→ tournament_participants
        ├─→ matches (as player1/player2)
        ├─→ challenges (as challenger/challenged)
        ├─→ vouchers
        ├─→ posts
        └─→ notifications

clubs ←───→ tournaments
       ├─→ vouchers
       └─→ challenges

tournaments ←→ matches
            └→ tournament_participants
```

---

*Last Updated: November 2025*
