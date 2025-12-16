# 🗄️ SUPABASE COMPLETE SCHEMA REPORT

**Generated:** Direct PostgreSQL Connection

---

## 📊 Summary

- **Total Tables:** 79
- **Total Records:** 8,698 rows

---

## 📋 Tables

### achievements (10 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `name` | text | ✗ | - |
| `description` | text | ✗ | - |
| `icon_url` | text | ✓ | - |
| `badge_color` | text | ✓ | '#FFD700'::text |
| `points_required` | integer | ✓ | 0 |
| `tournaments_required` | integer | ✓ | 0 |
| `wins_required` | integer | ✓ | 0 |
| `category` | text | ✓ | 'general'::text |
| `created_at` | timestamp with time zone | ✓ | now() |
| `updated_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Unique:** name

**Indexes:** 2 indexes

---

### admin_activity_logs (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `admin_id` | uuid | ✓ | - |
| `action` | text | ✗ | - |
| `target_type` | text | ✓ | - |
| `target_id` | uuid | ✓ | - |
| `details` | jsonb | ✓ | - |
| `created_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `admin_id` → `users.id`

**Indexes:** 1 indexes

---

### admin_guide_progress (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | uuid_generate_v4() |
| `user_id` | uuid | ✗ | - |
| `guide_id` | text | ✗ | - |
| `current_step` | integer | ✓ | 0 |
| `is_completed` | boolean | ✓ | false |
| `completed_at` | timestamp with time zone | ✓ | - |
| `last_accessed_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `user_id` → `users.id`
- **Unique:** guide_id, guide_id, user_id, user_id

**Indexes:** 4 indexes

---

### admin_guides (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | text | ✗ | - |
| `title` | text | ✗ | - |
| `description` | text | ✗ | - |
| `category` | text | ✗ | - |
| `steps` | jsonb | ✗ | '[]'::jsonb |
| `estimated_minutes` | integer | ✓ | 5 |
| `tags` | ARRAY | ✓ | '{}'::text[] |
| `priority` | integer | ✓ | 999 |
| `is_new` | boolean | ✓ | false |
| `version` | text | ✗ | - |
| `last_updated` | timestamp with time zone | ✓ | now() |
| `created_by` | uuid | ✓ | - |
| `created_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `created_by` → `users.id`

**Indexes:** 3 indexes

---

### admin_logs (2 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | uuid_generate_v4() |
| `admin_id` | uuid | ✓ | - |
| `action` | character varying(50) | ✗ | - |
| `target_id` | uuid | ✗ | - |
| `details` | jsonb | ✓ | - |
| `created_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `admin_id` → `users.id`

**Indexes:** 3 indexes

---

### admin_quick_help (5 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | uuid_generate_v4() |
| `screen_id` | text | ✗ | - |
| `element_id` | text | ✗ | - |
| `title` | text | ✗ | - |
| `description` | text | ✗ | - |
| `related_guide_id` | text | ✓ | - |
| `priority` | integer | ✓ | 999 |
| `is_active` | boolean | ✓ | true |
| `created_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Unique:** element_id, element_id, screen_id, screen_id

**Indexes:** 3 indexes

---

### announcement_reads (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | uuid_generate_v4() |
| `announcement_id` | uuid | ✓ | - |
| `user_id` | uuid | ✓ | - |
| `read_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `announcement_id` → `announcements.id`
  - `user_id` → `None.None`
- **Unique:** announcement_id, user_id, user_id, announcement_id

**Indexes:** 2 indexes

---

### announcements (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | uuid_generate_v4() |
| `club_id` | uuid | ✓ | - |
| `title` | character varying(255) | ✗ | - |
| `content` | text | ✗ | - |
| `priority` | character varying(20) | ✓ | 'normal'::character varying |
| `type` | character varying(20) | ✓ | 'general'::character varying |
| `is_pinned` | boolean | ✓ | false |
| `expires_at` | timestamp with time zone | ✓ | - |
| `target_roles` | ARRAY | ✓ | ARRAY['member'::text] |
| `attachments` | jsonb | ✓ | - |
| `created_by` | uuid | ✓ | - |
| `created_at` | timestamp with time zone | ✓ | now() |
| `updated_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `club_id` → `clubs.id`
  - `created_by` → `None.None`

**Indexes:** 1 indexes

---

### attendance_notifications (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `club_id` | uuid | ✗ | - |
| `staff_id` | uuid | ✓ | - |
| `recipient_id` | uuid | ✗ | - |
| `notification_type` | text | ✗ | - |
| `title` | text | ✗ | - |
| `message` | text | ✗ | - |
| `is_read` | boolean | ✓ | false |
| `sent_at` | timestamp without time zone | ✓ | now() |
| `read_at` | timestamp without time zone | ✓ | - |
| `metadata` | jsonb | ✓ | - |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `club_id` → `clubs.id`
  - `recipient_id` → `users.id`
  - `staff_id` → `club_staff.id`

**Indexes:** 3 indexes

---

### challenge_configurations (6 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `bet_amount` | integer | ✗ | - |
| `race_to` | integer | ✗ | - |
| `description` | character varying(100) | ✗ | - |
| `description_vi` | character varying(100) | ✗ | - |
| `is_active` | boolean | ✓ | true |
| `created_at` | timestamp without time zone | ✓ | now() |
| `updated_at` | timestamp without time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Unique:** bet_amount

**Indexes:** 3 indexes

---

### challenges (9 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `challenger_id` | uuid | ✓ | - |
| `challenged_id` | uuid | ✓ | - |
| `challenge_type` | character varying(50) | ✗ | 'giao_luu'::character varying |
| `message` | text | ✓ | - |
| `stakes_type` | character varying(50) | ✓ | 'none'::character varying |
| `stakes_amount` | integer | ✓ | 0 |
| `match_conditions` | jsonb | ✓ | '{}'::jsonb |
| `status` | character varying(50) | ✓ | 'pending'::character varying |
| `response_message` | text | ✓ | - |
| `expires_at` | timestamp with time zone | ✓ | (now() + '24:00:00'::interval) |
| `responded_at` | timestamp with time zone | ✓ | - |
| `created_at` | timestamp with time zone | ✓ | now() |
| `updated_at` | timestamp with time zone | ✓ | now() |
| `challenge_config_id` | uuid | ✓ | - |
| `handicap_challenger` | numeric | ✓ | 0.0 |
| `handicap_challenged` | numeric | ✓ | 0.0 |
| `rank_difference` | integer | ✓ | 0 |
| `club_id` | uuid | ✓ | - |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `challenge_config_id` → `challenge_configurations.id`
  - `club_id` → `clubs.id`
  - `challenged_id` → `users.id`
  - `challenger_id` → `users.id`

**Indexes:** 12 indexes

---

### chat_messages (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | uuid_generate_v4() |
| `room_id` | uuid | ✓ | - |
| `sender_id` | uuid | ✓ | - |
| `message` | text | ✗ | - |
| `message_type` | character varying(20) | ✓ | 'text'::character varying |
| `attachments` | jsonb | ✓ | - |
| `reply_to` | uuid | ✓ | - |
| `edited_at` | timestamp with time zone | ✓ | - |
| `is_deleted` | boolean | ✓ | false |
| `created_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `reply_to` → `chat_messages.id`
  - `sender_id` → `users.id`

**Indexes:** 4 indexes

---

### chat_room_members (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | uuid_generate_v4() |
| `room_id` | uuid | ✓ | - |
| `user_id` | uuid | ✓ | - |
| `joined_at` | timestamp with time zone | ✓ | now() |
| `role` | character varying(20) | ✓ | 'member'::character varying |
| `last_read_at` | timestamp with time zone | ✓ | - |
| `created_at` | timestamp with time zone | ✓ | now() |
| `updated_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `room_id` → `chat_rooms.id`
- **Unique:** user_id, room_id, room_id, user_id

**Indexes:** 5 indexes

---

### chat_rooms (4 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | uuid_generate_v4() |
| `club_id` | uuid | ✓ | - |
| `name` | character varying(255) | ✓ | - |
| `description` | text | ✓ | - |
| `type` | character varying(20) | ✓ | 'general'::character varying |
| `is_private` | boolean | ✓ | false |
| `created_by` | uuid | ✓ | - |
| `created_at` | timestamp with time zone | ✓ | now() |
| `updated_at` | timestamp with time zone | ✓ | now() |
| `user1_id` | uuid | ✓ | - |
| `user2_id` | uuid | ✓ | - |
| `room_type` | character varying(20) | ✓ | 'group'::character varying |
| `last_message_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `club_id` → `clubs.id`
  - `created_by` → `None.None`
  - `user1_id` → `users.id`
  - `user2_id` → `users.id`

**Indexes:** 6 indexes

---

### club_follows (2 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `user_id` | uuid | ✗ | - |
| `club_id` | uuid | ✗ | - |
| `created_at` | timestamp with time zone | ✓ | now() |
| `updated_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Unique:** club_id, club_id, user_id, user_id

**Indexes:** 4 indexes

---

### club_members (1 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `club_id` | uuid | ✓ | - |
| `user_id` | uuid | ✓ | - |
| `joined_at` | timestamp with time zone | ✓ | CURRENT_TIMESTAMP |
| `is_favorite` | boolean | ✓ | false |
| `role` | character varying(50) | ✓ | 'member'::character varying |
| `status` | character varying(20) | ✓ | 'active'::character varying |
| `created_at` | timestamp with time zone | ✓ | now() |
| `updated_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `club_id` → `clubs.id`
  - `user_id` → `users.id`
- **Unique:** club_id, user_id, user_id, club_id

**Indexes:** 6 indexes

---

### club_reviews (1 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `club_id` | uuid | ✓ | - |
| `user_id` | uuid | ✓ | - |
| `rating` | integer | ✗ | - |
| `review_text` | text | ✓ | - |
| `visit_date` | date | ✓ | - |
| `created_at` | timestamp with time zone | ✓ | CURRENT_TIMESTAMP |
| `updated_at` | timestamp with time zone | ✓ | CURRENT_TIMESTAMP |
| `facility_rating` | numeric | ✓ | - |
| `service_rating` | numeric | ✓ | - |
| `atmosphere_rating` | numeric | ✓ | - |
| `price_rating` | numeric | ✓ | - |
| `comment` | text | ✓ | - |
| `image_urls` | ARRAY | ✓ | - |
| `helpful_count` | integer | ✓ | 0 |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `club_id` → `clubs.id`
  - `user_id` → `users.id`
- **Unique:** user_id, user_id, club_id, club_id

**Indexes:** 6 indexes

---

### club_staff (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `club_id` | uuid | ✗ | - |
| `user_id` | uuid | ✗ | - |
| `staff_role` | character varying(50) | ✓ | 'staff'::character varying |
| `commission_rate` | numeric | ✓ | 5.00 |
| `can_enter_scores` | boolean | ✓ | true |
| `can_manage_tournaments` | boolean | ✓ | false |
| `can_view_reports` | boolean | ✓ | false |
| `can_manage_staff` | boolean | ✓ | false |
| `hired_at` | timestamp with time zone | ✓ | now() |
| `terminated_at` | timestamp with time zone | ✓ | - |
| `is_active` | boolean | ✓ | true |
| `notes` | text | ✓ | - |
| `created_at` | timestamp with time zone | ✓ | now() |
| `updated_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `club_id` → `clubs.id`
  - `user_id` → `users.id`
- **Unique:** user_id, user_id, club_id, club_id

**Indexes:** 4 indexes

---

### clubs (1 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `owner_id` | uuid | ✓ | - |
| `name` | text | ✗ | - |
| `description` | text | ✓ | - |
| `address` | text | ✓ | - |
| `phone` | text | ✓ | - |
| `email` | text | ✓ | - |
| `website_url` | text | ✓ | - |
| `cover_image_url` | text | ✓ | - |
| `profile_image_url` | text | ✓ | - |
| `established_year` | integer | ✓ | - |
| `total_tables` | integer | ✓ | 1 |
| `opening_hours` | jsonb | ✓ | - |
| `amenities` | ARRAY | ✓ | - |
| `price_per_hour` | numeric | ✓ | - |
| `is_verified` | boolean | ✓ | false |
| `is_active` | boolean | ✓ | true |
| `rating` | numeric | ✓ | 0.00 |
| `total_reviews` | integer | ✓ | 0 |
| `latitude` | numeric | ✓ | - |
| `longitude` | numeric | ✓ | - |
| `created_at` | timestamp with time zone | ✓ | CURRENT_TIMESTAMP |
| `updated_at` | timestamp with time zone | ✓ | CURRENT_TIMESTAMP |
| `approval_status` | character varying(20) | ✓ | 'pending'::character varying |
| `rejection_reason` | text | ✓ | - |
| `approved_at` | timestamp with time zone | ✓ | - |
| `approved_by` | uuid | ✓ | - |
| `logo_url` | text | ✓ | - |
| `attendance_qr_code` | text | ✓ | - |
| `qr_secret_key` | text | ✓ | - |
| `qr_created_at` | timestamp without time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `approved_by` → `users.id`

**Indexes:** 11 indexes

---

### comments (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `post_id` | uuid | ✓ | - |
| `user_id` | uuid | ✓ | - |
| `parent_comment_id` | uuid | ✓ | - |
| `content` | text | ✗ | - |
| `like_count` | integer | ✓ | 0 |
| `created_at` | timestamp with time zone | ✓ | CURRENT_TIMESTAMP |
| `updated_at` | timestamp with time zone | ✓ | CURRENT_TIMESTAMP |
| `likes_count` | integer | ✓ | 0 |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `parent_comment_id` → `comments.id`

**Indexes:** 6 indexes

---

### customer_transactions (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `customer_id` | uuid | ✗ | - |
| `club_id` | uuid | ✗ | - |
| `staff_referral_id` | uuid | ✓ | - |
| `transaction_type` | character varying(50) | ✗ | - |
| `amount` | numeric | ✗ | - |
| `commission_eligible` | boolean | ✓ | true |
| `commission_rate` | numeric | ✓ | 0 |
| `commission_amount` | numeric | ✓ | 0 |
| `tournament_id` | uuid | ✓ | - |
| `match_id` | uuid | ✓ | - |
| `description` | text | ✓ | - |
| `payment_method` | character varying(50) | ✓ | - |
| `transaction_date` | timestamp with time zone | ✓ | now() |
| `created_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `club_id` → `clubs.id`
  - `customer_id` → `users.id`
  - `match_id` → `matches.id`
  - `staff_referral_id` → `staff_referrals.id`
  - `tournament_id` → `tournaments.id`

**Indexes:** 4 indexes

---

### fraud_detection_rules (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `club_id` | uuid | ✗ | - |
| `rule_name` | character varying(255) | ✗ | - |
| `rule_type` | character varying(50) | ✗ | - |
| `parameters` | jsonb | ✗ | '{}'::jsonb |
| `weight` | numeric | ✓ | 1.00 |
| `threshold` | numeric | ✓ | - |
| `action` | character varying(50) | ✓ | 'flag'::character varying |
| `is_active` | boolean | ✓ | true |
| `created_at` | timestamp with time zone | ✓ | now() |
| `updated_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `club_id` → `clubs.id`

**Indexes:** 3 indexes

---

### handicap_rules (24 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `rank_difference_type` | character varying(20) | ✗ | - |
| `rank_difference_value` | integer | ✗ | - |
| `bet_amount` | integer | ✗ | - |
| `handicap_value` | numeric | ✗ | - |
| `description` | character varying(100) | ✓ | - |
| `description_vi` | character varying(100) | ✓ | - |
| `created_at` | timestamp without time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `bet_amount` → `challenge_configurations.bet_amount`
- **Unique:** bet_amount, bet_amount, rank_difference_type, rank_difference_type

**Indexes:** 3 indexes

---

### hidden_posts (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `user_id` | uuid | ✗ | - |
| `post_id` | uuid | ✗ | - |
| `created_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `post_id` → `posts.id`
  - `user_id` → `users.id`
- **Unique:** post_id, post_id, user_id, user_id

**Indexes:** 5 indexes

---

### matches (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `tournament_id` | uuid | ✓ | - |
| `player1_id` | uuid | ✓ | - |
| `player2_id` | uuid | ✓ | - |
| `winner_id` | uuid | ✓ | - |
| `round_number` | integer | ✓ | - |
| `match_number` | integer | ✗ | - |
| `scheduled_time` | timestamp with time zone | ✓ | - |
| `start_time` | timestamp with time zone | ✓ | - |
| `end_time` | timestamp with time zone | ✓ | - |
| `player1_score` | integer | ✓ | 0 |
| `player2_score` | integer | ✓ | 0 |
| `status` | USER-DEFINED | ✓ | 'pending'::match_status |
| `notes` | text | ✓ | - |
| `created_at` | timestamp with time zone | ✓ | CURRENT_TIMESTAMP |
| `updated_at` | timestamp with time zone | ✓ | CURRENT_TIMESTAMP |
| `match_type` | character varying(50) | ✓ | 'tournament'::character var... |
| `invitation_type` | character varying(50) | ✓ | 'none'::character varying |
| `stakes_type` | character varying(50) | ✓ | 'none'::character varying |
| `spa_stakes_amount` | integer | ✓ | 0 |
| `challenger_id` | uuid | ✓ | - |
| `challenge_message` | text | ✓ | - |
| `response_message` | text | ✓ | - |
| `match_conditions` | jsonb | ✓ | '{}'::jsonb |
| `is_public_challenge` | boolean | ✓ | false |
| `expires_at` | timestamp with time zone | ✓ | - |
| `accepted_at` | timestamp with time zone | ✓ | - |
| `spa_payout_processed` | boolean | ✓ | false |
| `played_at` | timestamp with time zone | ✓ | - |
| `score_player1` | integer | ✓ | 0 |
| `score_player2` | integer | ✓ | 0 |
| `match_date` | timestamp with time zone | ✓ | now() |
| `duration_minutes` | integer | ✓ | - |
| `location` | character varying(255) | ✓ | - |
| `bracket_format` | text | ✓ | 'single_elimination'::text |
| `round` | text | ✓ | - |
| `bracket_position` | integer | ✓ | - |
| `parent_match_id` | uuid | ✓ | - |
| `next_match_id` | uuid | ✓ | - |
| `match_level` | integer | ✓ | - |
| `is_final` | boolean | ✓ | false |
| `is_third_place` | boolean | ✓ | false |
| `group_id` | character varying(10) | ✓ | NULL::character varying |
| `winner_advances_to` | integer | ✓ | - |
| `loser_advances_to` | integer | ✓ | - |
| `bracket_type` | character varying(10) | ✓ | 'WB'::character varying |
| `bracket_group` | character varying(5) | ✓ | - |
| `stage_round` | integer | ✓ | 1 |
| `display_order` | integer | ✓ | 0 |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `challenger_id` → `users.id`
  - `player1_id` → `users.id`
  - `player2_id` → `users.id`
  - `tournament_id` → `tournaments.id`
  - `winner_id` → `users.id`

**Indexes:** 20 indexes

---

### member_activities (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | uuid_generate_v4() |
| `club_id` | uuid | ✓ | - |
| `user_id` | uuid | ✓ | - |
| `action` | character varying(100) | ✗ | - |
| `description` | text | ✓ | - |
| `metadata` | jsonb | ✓ | - |
| `ip_address` | inet | ✓ | - |
| `user_agent` | text | ✓ | - |
| `created_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `club_id` → `clubs.id`
  - `user_id` → `None.None`

**Indexes:** 3 indexes

---

### member_statistics (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | uuid_generate_v4() |
| `club_id` | uuid | ✓ | - |
| `user_id` | uuid | ✓ | - |
| `matches_played` | integer | ✓ | 0 |
| `matches_won` | integer | ✓ | 0 |
| `matches_lost` | integer | ✓ | 0 |
| `tournaments_joined` | integer | ✓ | 0 |
| `tournaments_won` | integer | ✓ | 0 |
| `total_score` | integer | ✓ | 0 |
| `average_score` | numeric | ✓ | 0.00 |
| `last_activity_at` | timestamp with time zone | ✓ | - |
| `updated_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `club_id` → `clubs.id`
  - `user_id` → `None.None`
- **Unique:** club_id, user_id, user_id, club_id

**Indexes:** 2 indexes

---

### membership_requests (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | uuid_generate_v4() |
| `club_id` | uuid | ✓ | - |
| `user_id` | uuid | ✓ | - |
| `membership_type` | character varying(20) | ✓ | 'regular'::character varying |
| `status` | character varying(20) | ✓ | 'pending'::character varying |
| `message` | text | ✓ | - |
| `processed_by` | uuid | ✓ | - |
| `processed_at` | timestamp with time zone | ✓ | - |
| `rejection_reason` | text | ✓ | - |
| `notes` | text | ✓ | - |
| `additional_data` | jsonb | ✓ | - |
| `created_at` | timestamp with time zone | ✓ | now() |
| `updated_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `club_id` → `clubs.id`
  - `processed_by` → `None.None`
  - `user_id` → `None.None`

**Indexes:** 3 indexes

---

### notification_preferences (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `user_id` | uuid | ✗ | - |
| `all_notifications_enabled` | boolean | ✓ | true |
| `push_notifications_enabled` | boolean | ✓ | true |
| `email_notifications_enabled` | boolean | ✓ | false |
| `tournament_notifications_enabled` | boolean | ✓ | true |
| `club_notifications_enabled` | boolean | ✓ | true |
| `challenge_notifications_enabled` | boolean | ✓ | true |
| `match_notifications_enabled` | boolean | ✓ | true |
| `social_notifications_enabled` | boolean | ✓ | true |
| `system_notifications_enabled` | boolean | ✓ | true |
| `quiet_hours_enabled` | boolean | ✓ | false |
| `quiet_hours_start` | time without time zone | ✓ | - |
| `quiet_hours_end` | time without time zone | ✓ | - |
| `created_at` | timestamp with time zone | ✓ | now() |
| `updated_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `user_id` → `None.None`
- **Unique:** user_id

**Indexes:** 2 indexes

---

### notification_templates (6 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | uuid_generate_v4() |
| `name` | text | ✗ | - |
| `type` | text | ✗ | - |
| `title_template` | text | ✗ | - |
| `message_template` | text | ✗ | - |
| `variables` | jsonb | ✓ | '[]'::jsonb |
| `description` | text | ✓ | - |
| `is_active` | boolean | ✓ | true |
| `usage_count` | integer | ✓ | 0 |
| `created_by` | uuid | ✓ | - |
| `created_at` | timestamp with time zone | ✓ | now() |
| `updated_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `created_by` → `users.id`
- **Unique:** name

**Indexes:** 2 indexes

---

### notifications (2 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | uuid_generate_v4() |
| `user_id` | uuid | ✓ | - |
| `club_id` | uuid | ✓ | - |
| `type` | character varying(50) | ✗ | - |
| `title` | character varying(255) | ✗ | - |
| `message` | text | ✗ | - |
| `data` | jsonb | ✓ | - |
| `is_read` | boolean | ✓ | false |
| `read_at` | timestamp with time zone | ✓ | - |
| `priority` | character varying(20) | ✓ | 'normal'::character varying |
| `created_at` | timestamp with time zone | ✓ | now() |
| `action_type` | character varying(50) | ✓ | 'none'::character varying |
| `action_data` | jsonb | ✓ | '{}'::jsonb |
| `expires_at` | timestamp with time zone | ✓ | - |
| `is_dismissed` | boolean | ✓ | false |
| `status` | text | ✓ | 'delivered'::text |
| `delivered_at` | timestamp with time zone | ✓ | now() |
| `clicked_at` | timestamp with time zone | ✓ | - |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `club_id` → `clubs.id`

**Indexes:** 8 indexes

---

### notifications_archive (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | uuid_generate_v4() |
| `user_id` | uuid | ✓ | - |
| `club_id` | uuid | ✓ | - |
| `type` | character varying(50) | ✗ | - |
| `title` | character varying(255) | ✗ | - |
| `message` | text | ✗ | - |
| `data` | jsonb | ✓ | - |
| `is_read` | boolean | ✓ | false |
| `read_at` | timestamp with time zone | ✓ | - |
| `priority` | character varying(20) | ✓ | 'normal'::character varying |
| `created_at` | timestamp with time zone | ✓ | now() |
| `action_type` | character varying(50) | ✓ | 'none'::character varying |
| `action_data` | jsonb | ✓ | '{}'::jsonb |
| `expires_at` | timestamp with time zone | ✓ | - |
| `is_dismissed` | boolean | ✓ | false |

**Constraints:**

- **Primary Key:** id

**Indexes:** 4 indexes

---

### otp_codes (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `phone` | text | ✗ | - |
| `otp_code` | text | ✗ | - |
| `purpose` | text | ✓ | 'password_reset'::text |
| `expires_at` | timestamp with time zone | ✗ | - |
| `used` | boolean | ✓ | false |
| `used_at` | timestamp with time zone | ✓ | - |
| `created_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id

**Indexes:** 3 indexes

---

### popular_hashtags (10 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `hashtag` | text | ✗ | - |
| `use_count` | integer | ✓ | 0 |
| `last_used_at` | timestamp with time zone | ✓ | now() |
| `created_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Unique:** hashtag

**Indexes:** 5 indexes

---

### post_comments (2 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `user_id` | uuid | ✓ | - |
| `post_id` | uuid | ✓ | - |
| `content` | text | ✗ | - |
| `created_at` | timestamp with time zone | ✗ | timezone('utc'::text, now()) |
| `updated_at` | timestamp with time zone | ✗ | timezone('utc'::text, now()) |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `post_id` → `posts.id`
  - `user_id` → `users.id`

**Indexes:** 5 indexes

---

### post_interactions (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `post_id` | uuid | ✓ | - |
| `user_id` | uuid | ✓ | - |
| `interaction_type` | text | ✗ | - |
| `created_at` | timestamp with time zone | ✓ | CURRENT_TIMESTAMP |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `post_id` → `posts.id`
  - `user_id` → `users.id`
- **Unique:** user_id, user_id, user_id, interaction_type, interaction_type, interaction_type, post_id, post_id, post_id

**Indexes:** 4 indexes

---

### post_likes (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `user_id` | uuid | ✓ | - |
| `post_id` | uuid | ✓ | - |
| `created_at` | timestamp with time zone | ✗ | timezone('utc'::text, now()) |
| `updated_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Unique:** post_id, post_id, user_id, user_id

**Indexes:** 5 indexes

---

### posts (1 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `user_id` | uuid | ✓ | - |
| `content` | text | ✓ | - |
| `post_type` | USER-DEFINED | ✓ | 'text'::post_type |
| `image_urls` | ARRAY | ✓ | - |
| `location` | text | ✓ | - |
| `hashtags` | ARRAY | ✓ | - |
| `tournament_id` | uuid | ✓ | - |
| `club_id` | uuid | ✓ | - |
| `like_count` | integer | ✓ | 0 |
| `comment_count` | integer | ✓ | 0 |
| `share_count` | integer | ✓ | 0 |
| `is_public` | boolean | ✓ | true |
| `created_at` | timestamp with time zone | ✓ | CURRENT_TIMESTAMP |
| `updated_at` | timestamp with time zone | ✓ | CURRENT_TIMESTAMP |
| `likes_count` | integer | ✓ | 0 |
| `comments_count` | integer | ✓ | 0 |
| `is_featured` | boolean | ✓ | false |
| `visibility` | character varying(20) | ✓ | 'public'::character varying |
| `video_url` | text | ✓ | - |
| `video_platform` | character varying(20) | ✓ | 'youtube'::character varying |
| `video_duration` | integer | ✓ | - |
| `video_thumbnail_url` | text | ✓ | - |
| `video_uploaded_at` | timestamp with time zone | ✓ | - |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `tournament_id` → `tournaments.id`

**Indexes:** 10 indexes

---

### rank_change_logs (1 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `user_id` | uuid | ✓ | - |
| `old_rank` | text | ✓ | - |
| `new_rank` | text | ✓ | - |
| `changed_by` | uuid | ✓ | - |
| `reason` | text | ✓ | - |
| `club_id` | uuid | ✓ | - |
| `created_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `changed_by` → `users.id`
  - `club_id` → `clubs.id`
  - `user_id` → `users.id`

**Indexes:** 3 indexes

---

### rank_requests (2 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `user_id` | uuid | ✗ | - |
| `club_id` | uuid | ✗ | - |
| `status` | USER-DEFINED | ✗ | 'pending'::request_status |
| `requested_at` | timestamp with time zone | ✗ | CURRENT_TIMESTAMP |
| `reviewed_at` | timestamp with time zone | ✓ | - |
| `reviewed_by` | uuid | ✓ | - |
| `rejection_reason` | text | ✓ | - |
| `notes` | text | ✓ | - |
| `evidence_urls` | ARRAY | ✓ | - |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `club_id` → `clubs.id`
  - `reviewed_by` → `users.id`
  - `user_id` → `users.id`
- **Unique:** user_id, user_id, club_id, club_id

**Indexes:** 7 indexes

---

### rank_system (12 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `rank_code` | character varying(10) | ✗ | - |
| `rank_value` | integer | ✗ | - |
| `rank_name` | character varying(50) | ✗ | - |
| `rank_name_vi` | character varying(50) | ✗ | - |
| `color_hex` | character varying(7) | ✗ | - |
| `elo_min` | integer | ✓ | - |
| `elo_max` | integer | ✓ | - |
| `created_at` | timestamp without time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Unique:** rank_code, rank_value

**Indexes:** 5 indexes

---

### referral_codes (35 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `user_id` | uuid | ✓ | - |
| `code` | text | ✗ | - |
| `code_type` | text | ✓ | 'general'::text |
| `max_uses` | integer | ✓ | - |
| `current_uses` | integer | ✓ | 0 |
| `rewards` | jsonb | ✓ | '{"referred": {"spa_points"... |
| `expires_at` | timestamp without time zone | ✓ | - |
| `is_active` | boolean | ✓ | true |
| `created_at` | timestamp without time zone | ✓ | now() |
| `updated_at` | timestamp without time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `user_id` → `users.id`
- **Unique:** code

**Indexes:** 5 indexes

---

### referral_usage (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `referral_code_id` | uuid | ✓ | - |
| `referrer_id` | uuid | ✓ | - |
| `referred_user_id` | uuid | ✓ | - |
| `bonus_awarded` | jsonb | ✗ | - |
| `status` | text | ✓ | 'completed'::text |
| `used_at` | timestamp without time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `referral_code_id` → `referral_codes.id`
  - `referred_user_id` → `users.id`
  - `referrer_id` → `users.id`

**Indexes:** 4 indexes

---

### refund_requests (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `tournament_id` | uuid | ✓ | - |
| `user_id` | uuid | ✗ | - |
| `amount` | numeric | ✗ | - |
| `reason` | text | ✗ | - |
| `additional_notes` | text | ✓ | - |
| `status` | character varying(20) | ✓ | 'pending'::character varying |
| `reviewed_by` | uuid | ✓ | - |
| `reviewed_at` | timestamp with time zone | ✓ | - |
| `rejection_reason` | text | ✓ | - |
| `cancelled_at` | timestamp with time zone | ✓ | - |
| `requested_at` | timestamp with time zone | ✓ | now() |
| `created_at` | timestamp with time zone | ✓ | now() |
| `updated_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `reviewed_by` → `users.id`
  - `tournament_id` → `tournaments.id`
  - `user_id` → `users.id`

**Indexes:** 4 indexes

---

### saved_posts (2 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `user_id` | uuid | ✗ | - |
| `post_id` | uuid | ✗ | - |
| `created_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `post_id` → `posts.id`
  - `user_id` → `users.id`
- **Unique:** post_id, post_id, user_id, user_id

**Indexes:** 6 indexes

---

### scheduled_notifications (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | uuid_generate_v4() |
| `title` | text | ✗ | - |
| `message` | text | ✗ | - |
| `type` | text | ✗ | 'system'::text |
| `target_audience` | text | ✗ | - |
| `target_user_ids` | ARRAY | ✓ | - |
| `scheduled_at` | timestamp with time zone | ✗ | - |
| `status` | text | ✓ | 'pending'::text |
| `sent_at` | timestamp with time zone | ✓ | - |
| `sent_count` | integer | ✓ | 0 |
| `failed_count` | integer | ✓ | 0 |
| `data` | jsonb | ✓ | '{}'::jsonb |
| `created_by` | uuid | ✓ | - |
| `created_at` | timestamp with time zone | ✓ | now() |
| `updated_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `created_by` → `users.id`

**Indexes:** 2 indexes

---

### shift_expenses (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `shift_session_id` | uuid | ✓ | - |
| `club_id` | uuid | ✓ | - |
| `expense_type` | text | ✗ | - |
| `description` | text | ✗ | - |
| `amount` | numeric | ✗ | - |
| `payment_method` | text | ✗ | - |
| `receipt_url` | text | ✓ | - |
| `vendor_name` | text | ✓ | - |
| `approved_by` | uuid | ✓ | - |
| `approved_at` | timestamp without time zone | ✓ | - |
| `recorded_by` | uuid | ✓ | - |
| `recorded_at` | timestamp without time zone | ✓ | now() |
| `created_at` | timestamp without time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `approved_by` → `club_staff.id`
  - `club_id` → `clubs.id`
  - `recorded_by` → `club_staff.id`
  - `shift_session_id` → `shift_sessions.id`

**Indexes:** 3 indexes

---

### shift_inventory (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `shift_session_id` | uuid | ✓ | - |
| `club_id` | uuid | ✓ | - |
| `item_name` | text | ✗ | - |
| `category` | text | ✗ | - |
| `unit` | text | ✗ | - |
| `opening_stock` | integer | ✓ | 0 |
| `closing_stock` | integer | ✓ | - |
| `stock_used` | integer | ✓ | 0 |
| `stock_wasted` | integer | ✓ | 0 |
| `stock_added` | integer | ✓ | 0 |
| `unit_cost` | numeric | ✓ | - |
| `unit_price` | numeric | ✓ | - |
| `total_sold` | integer | ✓ | 0 |
| `revenue_generated` | numeric | ✓ | 0 |
| `notes` | text | ✓ | - |
| `created_at` | timestamp without time zone | ✓ | now() |
| `updated_at` | timestamp without time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `club_id` → `clubs.id`
  - `shift_session_id` → `shift_sessions.id`

**Indexes:** 3 indexes

---

### shift_reports (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `shift_session_id` | uuid | ✓ | - |
| `club_id` | uuid | ✓ | - |
| `revenue_summary` | jsonb | ✓ | '{}'::jsonb |
| `expense_summary` | jsonb | ✓ | '{}'::jsonb |
| `inventory_summary` | jsonb | ✓ | '{}'::jsonb |
| `total_revenue` | numeric | ✓ | 0 |
| `total_expenses` | numeric | ✓ | 0 |
| `net_profit` | numeric | ✓ | 0 |
| `tables_served` | integer | ✓ | 0 |
| `average_revenue_per_table` | numeric | ✓ | 0 |
| `customer_count` | integer | ✓ | 0 |
| `cash_expected` | numeric | ✓ | 0 |
| `cash_actual` | numeric | ✓ | 0 |
| `cash_variance` | numeric | ✓ | 0 |
| `status` | text | ✓ | 'draft'::text |
| `manager_notes` | text | ✓ | - |
| `reviewed_by` | uuid | ✓ | - |
| `reviewed_at` | timestamp without time zone | ✓ | - |
| `created_at` | timestamp without time zone | ✓ | now() |
| `updated_at` | timestamp without time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `club_id` → `clubs.id`
  - `reviewed_by` → `club_staff.id`
  - `shift_session_id` → `shift_sessions.id`

**Indexes:** 3 indexes

---

### shift_sessions (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `club_id` | uuid | ✓ | - |
| `staff_id` | uuid | ✓ | - |
| `shift_date` | date | ✗ | - |
| `start_time` | time without time zone | ✗ | - |
| `end_time` | time without time zone | ✓ | - |
| `actual_start_time` | timestamp without time zone | ✓ | - |
| `actual_end_time` | timestamp without time zone | ✓ | - |
| `opening_cash` | numeric | ✓ | 0 |
| `closing_cash` | numeric | ✓ | - |
| `expected_cash` | numeric | ✓ | 0 |
| `cash_difference` | numeric | ✓ | 0 |
| `total_revenue` | numeric | ✓ | 0 |
| `cash_revenue` | numeric | ✓ | 0 |
| `card_revenue` | numeric | ✓ | 0 |
| `digital_revenue` | numeric | ✓ | 0 |
| `status` | text | ✓ | 'active'::text |
| `notes` | text | ✓ | - |
| `handed_over_to` | uuid | ✓ | - |
| `handed_over_at` | timestamp without time zone | ✓ | - |
| `handover_notes` | text | ✓ | - |
| `created_at` | timestamp without time zone | ✓ | now() |
| `updated_at` | timestamp without time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `club_id` → `clubs.id`
  - `handed_over_to` → `club_staff.id`
  - `staff_id` → `club_staff.id`

**Indexes:** 4 indexes

---

### shift_transactions (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `shift_session_id` | uuid | ✓ | - |
| `club_id` | uuid | ✓ | - |
| `transaction_type` | text | ✗ | - |
| `category` | text | ✗ | - |
| `description` | text | ✗ | - |
| `amount` | numeric | ✗ | - |
| `payment_method` | text | ✗ | - |
| `table_number` | integer | ✓ | - |
| `customer_id` | uuid | ✓ | - |
| `receipt_number` | text | ✓ | - |
| `recorded_by` | uuid | ✓ | - |
| `recorded_at` | timestamp without time zone | ✓ | now() |
| `created_at` | timestamp without time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `club_id` → `clubs.id`
  - `customer_id` → `users.id`
  - `recorded_by` → `club_staff.id`
  - `shift_session_id` → `shift_sessions.id`

**Indexes:** 4 indexes

---

### spa_transactions (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `user_id` | uuid | ✓ | - |
| `match_id` | uuid | ✓ | - |
| `transaction_type` | character varying(50) | ✗ | - |
| `amount` | integer | ✗ | - |
| `balance_before` | integer | ✗ | - |
| `balance_after` | integer | ✗ | - |
| `description` | text | ✓ | - |
| `created_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `match_id` → `matches.id`
  - `user_id` → `users.id`

**Indexes:** 5 indexes

---

### spatial_ref_sys (8500 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `srid` | integer | ✗ | - |
| `auth_name` | character varying(256) | ✓ | - |
| `auth_srid` | integer | ✓ | - |
| `srtext` | character varying(2048) | ✓ | - |
| `proj4text` | character varying(2048) | ✓ | - |

**Constraints:**

- **Primary Key:** srid

**Indexes:** 1 indexes

---

### staff_attendance (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `shift_id` | uuid | ✗ | - |
| `staff_id` | uuid | ✗ | - |
| `club_id` | uuid | ✗ | - |
| `check_in_time` | timestamp without time zone | ✗ | now() |
| `check_in_method` | text | ✓ | 'qr_code'::text |
| `check_in_location` | USER-DEFINED | ✓ | - |
| `check_in_device_info` | jsonb | ✓ | - |
| `check_out_time` | timestamp without time zone | ✓ | - |
| `check_out_method` | text | ✓ | - |
| `check_out_location` | USER-DEFINED | ✓ | - |
| `check_out_device_info` | jsonb | ✓ | - |
| `total_hours_worked` | numeric | ✓ | - |
| `late_minutes` | integer | ✓ | 0 |
| `early_departure_minutes` | integer | ✓ | 0 |
| `attendance_status` | text | ✓ | 'checked_in'::text |
| `created_at` | timestamp without time zone | ✓ | now() |
| `updated_at` | timestamp without time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `club_id` → `clubs.id`
  - `shift_id` → `staff_shifts.id`
  - `staff_id` → `club_staff.id`

**Indexes:** 5 indexes

---

### staff_breaks (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `attendance_id` | uuid | ✗ | - |
| `break_start` | timestamp without time zone | ✗ | now() |
| `break_end` | timestamp without time zone | ✓ | - |
| `break_duration_minutes` | integer | ✓ | - |
| `break_type` | text | ✓ | 'rest'::text |
| `break_reason` | text | ✓ | - |
| `created_at` | timestamp without time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `attendance_id` → `staff_attendance.id`

**Indexes:** 3 indexes

---

### staff_commissions (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `staff_id` | uuid | ✗ | - |
| `club_id` | uuid | ✗ | - |
| `customer_transaction_id` | uuid | ✗ | - |
| `commission_type` | character varying(50) | ✗ | - |
| `commission_rate` | numeric | ✗ | - |
| `transaction_amount` | numeric | ✗ | - |
| `commission_amount` | numeric | ✗ | - |
| `is_paid` | boolean | ✓ | false |
| `paid_at` | timestamp with time zone | ✓ | - |
| `payment_method` | character varying(50) | ✓ | - |
| `payment_reference` | character varying(255) | ✓ | - |
| `payment_notes` | text | ✓ | - |
| `earned_at` | timestamp with time zone | ✓ | now() |
| `created_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `club_id` → `clubs.id`
  - `customer_transaction_id` → `customer_transactions.id`
  - `staff_id` → `club_staff.id`

**Indexes:** 4 indexes

---

### staff_performance (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `staff_id` | uuid | ✗ | - |
| `club_id` | uuid | ✗ | - |
| `period_start` | date | ✗ | - |
| `period_end` | date | ✗ | - |
| `total_referrals` | integer | ✓ | 0 |
| `active_customers` | integer | ✓ | 0 |
| `total_transactions` | integer | ✓ | 0 |
| `total_revenue_generated` | numeric | ✓ | 0 |
| `total_commissions_earned` | numeric | ✓ | 0 |
| `avg_transaction_value` | numeric | ✓ | 0 |
| `performance_score` | numeric | ✓ | 0 |
| `created_at` | timestamp with time zone | ✓ | now() |
| `updated_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `club_id` → `clubs.id`
  - `staff_id` → `club_staff.id`
- **Unique:** period_start, period_end, period_end, period_start, staff_id, staff_id, staff_id, period_end, period_start

**Indexes:** 3 indexes

---

### staff_referrals (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `staff_id` | uuid | ✗ | - |
| `customer_id` | uuid | ✗ | - |
| `club_id` | uuid | ✗ | - |
| `referral_method` | character varying(50) | ✓ | 'qr_code'::character varying |
| `referral_code` | character varying(100) | ✓ | - |
| `referred_at` | timestamp with time zone | ✓ | now() |
| `initial_bonus_spa` | integer | ✓ | 0 |
| `commission_rate` | numeric | ✓ | 5.00 |
| `total_customer_spending` | numeric | ✓ | 0 |
| `total_commission_earned` | numeric | ✓ | 0 |
| `is_active` | boolean | ✓ | true |
| `notes` | text | ✓ | - |
| `created_at` | timestamp with time zone | ✓ | now() |
| `updated_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `club_id` → `clubs.id`
  - `customer_id` → `users.id`
  - `staff_id` → `club_staff.id`
- **Unique:** staff_id, staff_id, customer_id, customer_id

**Indexes:** 5 indexes

---

### staff_shifts (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `club_id` | uuid | ✗ | - |
| `staff_id` | uuid | ✗ | - |
| `shift_date` | date | ✗ | - |
| `scheduled_start_time` | time without time zone | ✗ | - |
| `scheduled_end_time` | time without time zone | ✗ | - |
| `shift_status` | text | ✓ | 'scheduled'::text |
| `overtime_hours` | numeric | ✓ | 0 |
| `total_scheduled_hours` | numeric | ✓ | - |
| `created_at` | timestamp without time zone | ✓ | now() |
| `updated_at` | timestamp without time zone | ✓ | now() |
| `created_by` | uuid | ✓ | - |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `club_id` → `clubs.id`
  - `created_by` → `users.id`
  - `staff_id` → `club_staff.id`
- **Unique:** staff_id, staff_id, shift_date, shift_date

**Indexes:** 5 indexes

---

### staff_tasks (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `club_id` | uuid | ✗ | - |
| `template_id` | uuid | ✗ | - |
| `assigned_to` | uuid | ✗ | - |
| `assigned_by` | uuid | ✓ | - |
| `task_type` | character varying(50) | ✗ | - |
| `task_name` | character varying(255) | ✗ | - |
| `description` | text | ✗ | - |
| `priority` | character varying(20) | ✓ | 'normal'::character varying |
| `assigned_at` | timestamp with time zone | ✓ | now() |
| `due_at` | timestamp with time zone | ✓ | - |
| `started_at` | timestamp with time zone | ✓ | - |
| `completed_at` | timestamp with time zone | ✓ | - |
| `status` | character varying(20) | ✓ | 'assigned'::character varying |
| `completion_percentage` | integer | ✓ | 0 |
| `required_location` | jsonb | ✓ | - |
| `assignment_notes` | text | ✓ | - |
| `completion_notes` | text | ✓ | - |
| `created_at` | timestamp with time zone | ✓ | now() |
| `updated_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `assigned_by` → `club_staff.id`
  - `assigned_to` → `club_staff.id`
  - `club_id` → `clubs.id`
  - `template_id` → `task_templates.id`

**Indexes:** 6 indexes

---

### table_availability (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `club_id` | uuid | ✗ | - |
| `table_number` | integer | ✗ | - |
| `date` | date | ✗ | - |
| `time_slot` | time without time zone | ✗ | - |
| `is_available` | boolean | ✓ | true |
| `reason` | character varying(255) | ✓ | - |
| `created_at` | timestamp with time zone | ✗ | now() |
| `updated_at` | timestamp with time zone | ✗ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `club_id` → `clubs.id`
- **Unique:** date, date, date, time_slot, time_slot, time_slot, time_slot, table_number, table_number, table_number, table_number, club_id, club_id, club_id, date, club_id

**Indexes:** 4 indexes

---

### table_reservations (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `club_id` | uuid | ✗ | - |
| `user_id` | uuid | ✗ | - |
| `table_number` | integer | ✗ | - |
| `start_time` | timestamp with time zone | ✗ | - |
| `end_time` | timestamp with time zone | ✗ | - |
| `duration_hours` | numeric | ✗ | - |
| `price_per_hour` | numeric | ✗ | - |
| `total_price` | numeric | ✗ | - |
| `deposit_amount` | numeric | ✓ | 0 |
| `status` | character varying(20) | ✗ | 'pending'::character varying |
| `payment_status` | character varying(20) | ✗ | 'unpaid'::character varying |
| `payment_method` | character varying(50) | ✓ | - |
| `payment_transaction_id` | character varying(255) | ✓ | - |
| `notes` | text | ✓ | - |
| `special_requests` | text | ✓ | - |
| `number_of_players` | integer | ✓ | 2 |
| `confirmed_at` | timestamp with time zone | ✓ | - |
| `confirmed_by` | uuid | ✓ | - |
| `cancelled_at` | timestamp with time zone | ✓ | - |
| `cancelled_by` | uuid | ✓ | - |
| `cancellation_reason` | text | ✓ | - |
| `created_at` | timestamp with time zone | ✗ | now() |
| `updated_at` | timestamp with time zone | ✗ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `cancelled_by` → `None.None`
  - `club_id` → `clubs.id`
  - `confirmed_by` → `None.None`
  - `user_id` → `None.None`

**Indexes:** 7 indexes

---

### task_templates (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `club_id` | uuid | ✗ | - |
| `task_type` | character varying(50) | ✗ | - |
| `task_name` | character varying(255) | ✗ | - |
| `description` | text | ✗ | - |
| `requires_photo` | boolean | ✓ | true |
| `requires_location` | boolean | ✓ | true |
| `requires_timestamp` | boolean | ✓ | true |
| `estimated_duration` | integer | ✓ | - |
| `deadline_hours` | integer | ✓ | - |
| `instructions` | jsonb | ✓ | '{}'::jsonb |
| `verification_notes` | text | ✓ | - |
| `is_active` | boolean | ✓ | true |
| `created_at` | timestamp with time zone | ✓ | now() |
| `updated_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `club_id` → `clubs.id`

**Indexes:** 3 indexes

---

### task_verifications (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `task_id` | uuid | ✗ | - |
| `club_id` | uuid | ✗ | - |
| `staff_id` | uuid | ✗ | - |
| `photo_url` | text | ✗ | - |
| `photo_hash` | character varying(64) | ✗ | - |
| `photo_size` | integer | ✓ | - |
| `photo_mime_type` | character varying(50) | ✓ | 'image/jpeg'::character var... |
| `captured_latitude` | numeric | ✓ | - |
| `captured_longitude` | numeric | ✓ | - |
| `location_accuracy` | numeric | ✓ | - |
| `location_verified` | boolean | ✓ | false |
| `distance_from_required` | numeric | ✓ | - |
| `captured_at` | timestamp with time zone | ✗ | - |
| `server_received_at` | timestamp with time zone | ✓ | now() |
| `timestamp_verified` | boolean | ✓ | false |
| `time_drift_seconds` | integer | ✓ | - |
| `device_info` | jsonb | ✓ | '{}'::jsonb |
| `camera_metadata` | jsonb | ✓ | '{}'::jsonb |
| `verification_status` | character varying(20) | ✓ | 'pending'::character varying |
| `auto_verification_score` | numeric | ✓ | - |
| `manual_review_required` | boolean | ✓ | false |
| `reviewed_by` | uuid | ✓ | - |
| `reviewed_at` | timestamp with time zone | ✓ | - |
| `review_notes` | text | ✓ | - |
| `rejection_reason` | text | ✓ | - |
| `fraud_flags` | jsonb | ✓ | '{}'::jsonb |
| `confidence_score` | numeric | ✓ | - |
| `created_at` | timestamp with time zone | ✓ | now() |
| `updated_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `club_id` → `clubs.id`
  - `reviewed_by` → `club_staff.id`
  - `staff_id` → `club_staff.id`
  - `task_id` → `staff_tasks.id`

**Indexes:** 7 indexes

---

### tournament_completion_logs (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `tournament_id` | uuid | ✓ | - |
| `error_message` | text | ✓ | - |
| `error_type` | character varying(50) | ✓ | - |
| `created_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `tournament_id` → `tournaments.id`

**Indexes:** 1 indexes

---

### tournament_participants (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `tournament_id` | uuid | ✓ | - |
| `user_id` | uuid | ✓ | - |
| `registered_at` | timestamp with time zone | ✓ | CURRENT_TIMESTAMP |
| `payment_status` | text | ✓ | 'pending'::text |
| `seed_number` | integer | ✓ | - |
| `notes` | text | ✓ | - |
| `status` | character varying(20) | ✓ | 'registered'::character var... |
| `created_at` | timestamp with time zone | ✓ | now() |
| `updated_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `tournament_id` → `tournaments.id`
  - `user_id` → `users.id`
- **Unique:** user_id, user_id, tournament_id, tournament_id

**Indexes:** 7 indexes

---

### tournament_results (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `tournament_id` | uuid | ✓ | - |
| `participant_id` | uuid | ✓ | - |
| `participant_name` | text | ✗ | - |
| `position` | integer | ✗ | - |
| `matches_played` | integer | ✓ | 0 |
| `matches_won` | integer | ✓ | 0 |
| `matches_lost` | integer | ✓ | 0 |
| `games_won` | integer | ✓ | 0 |
| `games_lost` | integer | ✓ | 0 |
| `win_percentage` | integer | ✓ | 0 |
| `points` | integer | ✓ | 0 |
| `created_at` | timestamp with time zone | ✓ | now() |
| `updated_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `participant_id` → `users.id`
  - `tournament_id` → `tournaments.id`
- **Unique:** tournament_id, participant_id, participant_id, tournament_id

**Indexes:** 2 indexes

---

### tournaments (2 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `club_id` | uuid | ✓ | - |
| `organizer_id` | uuid | ✓ | - |
| `title` | text | ✗ | - |
| `description` | text | ✓ | - |
| `start_date` | timestamp with time zone | ✗ | - |
| `end_date` | timestamp with time zone | ✓ | - |
| `registration_deadline` | timestamp with time zone | ✗ | - |
| `max_participants` | integer | ✗ | - |
| `current_participants` | integer | ✓ | 0 |
| `entry_fee` | numeric | ✓ | 0.00 |
| `prize_pool` | numeric | ✓ | 0.00 |
| `prize_distribution` | jsonb | ✓ | - |
| `rules` | text | ✓ | - |
| `requirements` | text | ✓ | - |
| `skill_level_required` | USER-DEFINED | ✓ | - |
| `status` | USER-DEFINED | ✓ | 'upcoming'::tournament_status |
| `cover_image_url` | text | ✓ | - |
| `is_public` | boolean | ✓ | true |
| `created_at` | timestamp with time zone | ✓ | CURRENT_TIMESTAMP |
| `updated_at` | timestamp with time zone | ✓ | CURRENT_TIMESTAMP |
| `registration_end_time` | timestamp with time zone | ✓ | - |
| `cover_image` | text | ✓ | - |
| `has_live_stream` | boolean | ✓ | false |
| `game_format` | text | ✓ | '8-ball'::text |
| `bracket_format` | text | ✓ | 'single_elimination'::text |
| `prize_source` | text | ✓ | 'entry_fees'::text |
| `distribution_template` | text | ✓ | 'top_4'::text |
| `organizer_fee_percent` | numeric | ✓ | 10.00 |
| `sponsor_contribution` | numeric | ✓ | 0.00 |
| `custom_distribution` | jsonb | ✓ | - |
| `min_rank` | text | ✓ | - |
| `max_rank` | text | ✓ | - |
| `venue_address` | text | ✓ | - |
| `venue_contact` | text | ✓ | - |
| `venue_phone` | text | ✓ | - |
| `special_rules` | text | ✓ | - |
| `registration_fee_waiver` | boolean | ✓ | false |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `organizer_id` → `users.id`
  - `club_id` → `clubs.id`

**Indexes:** 15 indexes

---

### user_achievements (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `user_id` | uuid | ✓ | - |
| `achievement_id` | uuid | ✓ | - |
| `earned_at` | timestamp with time zone | ✓ | CURRENT_TIMESTAMP |
| `tournament_id` | uuid | ✓ | - |
| `created_at` | timestamp with time zone | ✓ | now() |
| `updated_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `tournament_id` → `tournaments.id`
- **Unique:** achievement_id, user_id, user_id, achievement_id

**Indexes:** 3 indexes

---

### user_follows (7 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `follower_id` | uuid | ✓ | - |
| `following_id` | uuid | ✓ | - |
| `created_at` | timestamp with time zone | ✓ | CURRENT_TIMESTAMP |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `follower_id` → `users.id`
  - `following_id` → `users.id`
- **Unique:** follower_id, following_id, following_id, follower_id

**Indexes:** 5 indexes

---

### user_preferences (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `user_id` | uuid | ✓ | - |
| `email_notifications` | boolean | ✓ | true |
| `push_notifications` | boolean | ✓ | true |
| `sms_notifications` | boolean | ✓ | false |
| `notify_match_invites` | boolean | ✓ | true |
| `notify_tournament_invites` | boolean | ✓ | true |
| `notify_challenges` | boolean | ✓ | true |
| `notify_match_results` | boolean | ✓ | true |
| `notify_spa_transactions` | boolean | ✓ | true |
| `notify_rank_changes` | boolean | ✓ | true |
| `notify_club_updates` | boolean | ✓ | false |
| `notify_system_updates` | boolean | ✓ | true |
| `show_online_status` | boolean | ✓ | true |
| `allow_challenges` | boolean | ✓ | true |
| `allow_friend_requests` | boolean | ✓ | true |
| `show_location` | boolean | ✓ | false |
| `show_stats_publicly` | boolean | ✓ | true |
| `preferred_game_types` | ARRAY | ✓ | ARRAY['8-ball'::text, '9-ba... |
| `max_challenge_distance` | integer | ✓ | 50 |
| `auto_accept_friends` | boolean | ✓ | false |
| `theme` | character varying(20) | ✓ | 'system'::character varying |
| `language` | character varying(10) | ✓ | 'vi'::character varying |
| `created_at` | timestamp with time zone | ✓ | now() |
| `updated_at` | timestamp with time zone | ✓ | now() |
| `notification_types` | jsonb | ✓ | '{"club_updates": true, "ma... |
| `privacy_settings` | jsonb | ✓ | '{"stats_public": true, "pr... |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `user_id` → `users.id`
- **Unique:** user_id

**Indexes:** 3 indexes

---

### user_privacy_settings (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `user_id` | uuid | ✗ | - |
| `show_in_social_feed` | boolean | ✓ | true |
| `show_in_challenge_list` | boolean | ✓ | true |
| `show_in_tournament_participants` | boolean | ✓ | true |
| `show_in_leaderboard` | boolean | ✓ | true |
| `show_real_name` | boolean | ✓ | false |
| `show_phone_number` | boolean | ✓ | false |
| `show_email` | boolean | ✓ | false |
| `show_location` | boolean | ✓ | true |
| `show_club_membership` | boolean | ✓ | true |
| `show_match_history` | boolean | ✓ | true |
| `show_win_loss_record` | boolean | ✓ | true |
| `show_current_rank` | boolean | ✓ | true |
| `show_achievements` | boolean | ✓ | true |
| `show_online_status` | boolean | ✓ | true |
| `allow_challenges_from_strangers` | boolean | ✓ | true |
| `allow_tournament_invitations` | boolean | ✓ | true |
| `allow_friend_requests` | boolean | ✓ | true |
| `notify_on_challenge` | boolean | ✓ | true |
| `notify_on_tournament_invite` | boolean | ✓ | true |
| `notify_on_friend_request` | boolean | ✓ | true |
| `notify_on_match_result` | boolean | ✓ | true |
| `searchable_by_username` | boolean | ✓ | true |
| `searchable_by_real_name` | boolean | ✓ | false |
| `searchable_by_phone` | boolean | ✓ | false |
| `appear_in_suggestions` | boolean | ✓ | true |
| `created_at` | timestamp with time zone | ✓ | now() |
| `updated_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `user_id` → `users.id`
- **Unique:** user_id

**Indexes:** 3 indexes

---

### user_vouchers (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `campaign_id` | uuid | ✗ | - |
| `user_id` | uuid | ✗ | - |
| `club_id` | uuid | ✗ | - |
| `voucher_code` | text | ✗ | - |
| `status` | text | ✗ | 'active'::text |
| `issue_reason` | text | ✓ | - |
| `issue_details` | jsonb | ✓ | '{}'::jsonb |
| `rewards` | jsonb | ✗ | '{}'::jsonb |
| `usage_rules` | jsonb | ✓ | '{}'::jsonb |
| `issued_at` | timestamp with time zone | ✓ | now() |
| `expires_at` | timestamp with time zone | ✓ | - |
| `used_at` | timestamp with time zone | ✓ | - |
| `used_details` | jsonb | ✓ | '{}'::jsonb |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `campaign_id` → `voucher_campaigns.id`
  - `club_id` → `clubs.id`
  - `user_id` → `users.id`
- **Unique:** voucher_code

**Indexes:** 8 indexes

---

### users (41 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | - |
| `email` | text | ✓ | - |
| `full_name` | text | ✗ | - |
| `username` | text | ✓ | - |
| `bio` | text | ✓ | - |
| `avatar_url` | text | ✓ | - |
| `phone` | text | ✓ | - |
| `date_of_birth` | date | ✓ | - |
| `role` | USER-DEFINED | ✓ | 'player'::user_role |
| `skill_level` | USER-DEFINED | ✓ | 'beginner'::skill_level |
| `total_wins` | integer | ✓ | 0 |
| `total_losses` | integer | ✓ | 0 |
| `total_tournaments` | integer | ✓ | 0 |
| `ranking_points` | integer | ✓ | 0 |
| `is_verified` | boolean | ✓ | false |
| `is_active` | boolean | ✓ | true |
| `location` | text | ✓ | - |
| `created_at` | timestamp with time zone | ✓ | CURRENT_TIMESTAMP |
| `updated_at` | timestamp with time zone | ✓ | CURRENT_TIMESTAMP |
| `display_name` | text | ✓ | - |
| `rank` | text | ✓ | - |
| `elo_rating` | integer | ✓ | - |
| `spa_points` | integer | ✓ | 0 |
| `favorite_game` | text | ✓ | '8-Ball'::text |
| `total_matches` | integer | ✓ | 0 |
| `wins` | integer | ✓ | 0 |
| `losses` | integer | ✓ | 0 |
| `win_streak` | integer | ✓ | 0 |
| `tournaments_played` | integer | ✓ | 0 |
| `tournament_wins` | integer | ✓ | 0 |
| `is_online` | boolean | ✓ | true |
| `last_seen` | timestamp with time zone | ✓ | now() |
| `cover_photo_url` | text | ✓ | - |
| `latitude` | numeric | ✓ | - |
| `longitude` | numeric | ✓ | - |
| `location_name` | text | ✓ | - |
| `spa_points_won` | integer | ✓ | 0 |
| `spa_points_lost` | integer | ✓ | 0 |
| `challenge_win_streak` | integer | ✓ | 0 |
| `is_available_for_challenges` | boolean | ✓ | true |
| `preferred_match_type` | character varying(50) | ✓ | 'both'::character varying |
| `max_challenge_distance` | integer | ✓ | 10 |
| `total_prize_pool` | integer | ✓ | 0 |
| `total_games` | integer | ✓ | 0 |
| `referral_stats` | jsonb | ✓ | '{"total_earned": 0, "total... |
| `referred_by` | uuid | ✓ | - |
| `referral_bonus_claimed` | boolean | ✓ | false |
| `tournament_podiums` | integer | ✓ | 0 |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `id` → `None.None`
- **Unique:** username, email, username

**Indexes:** 23 indexes

---

### verification_audit_log (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `verification_id` | uuid | ✗ | - |
| `action` | character varying(50) | ✗ | - |
| `performed_by` | uuid | ✓ | - |
| `performed_at` | timestamp with time zone | ✓ | now() |
| `old_status` | character varying(20) | ✓ | - |
| `new_status` | character varying(20) | ✓ | - |
| `reason` | text | ✓ | - |
| `ip_address` | inet | ✓ | - |
| `user_agent` | text | ✓ | - |
| `created_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `performed_by` → `club_staff.id`
  - `verification_id` → `task_verifications.id`

**Indexes:** 3 indexes

---

### voucher_campaigns (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `club_id` | uuid | ✓ | - |
| `title` | text | ✗ | - |
| `description` | text | ✗ | - |
| `image_url` | text | ✓ | - |
| `campaign_type` | text | ✗ | - |
| `status` | text | ✗ | 'draft'::text |
| `start_date` | timestamp with time zone | ✗ | - |
| `end_date` | timestamp with time zone | ✗ | - |
| `target_criteria` | jsonb | ✗ | '{}'::jsonb |
| `rules` | jsonb | ✗ | '{}'::jsonb |
| `rewards` | jsonb | ✗ | '{}'::jsonb |
| `budget_info` | jsonb | ✗ | '{}'::jsonb |
| `max_redemptions` | integer | ✓ | 100 |
| `max_per_user` | integer | ✓ | 1 |
| `total_issued` | integer | ✓ | 0 |
| `total_used` | integer | ✓ | 0 |
| `created_at` | timestamp with time zone | ✓ | now() |
| `updated_at` | timestamp with time zone | ✓ | now() |
| `created_by` | uuid | ✓ | - |
| `approved_by` | uuid | ✓ | - |
| `approved_at` | timestamp with time zone | ✓ | - |
| `rejection_reason` | text | ✓ | - |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `approved_by` → `users.id`
  - `club_id` → `clubs.id`
  - `created_by` → `users.id`

**Indexes:** 5 indexes

---

### voucher_registration_requests (3 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `club_id` | uuid | ✗ | - |
| `campaign_id` | uuid | ✓ | - |
| `status` | text | ✗ | 'pending'::text |
| `title` | text | ✗ | - |
| `description` | text | ✗ | - |
| `proposed_rewards` | jsonb | ✗ | '{}'::jsonb |
| `target_criteria` | jsonb | ✗ | '{}'::jsonb |
| `requested_budget` | jsonb | ✗ | '{}'::jsonb |
| `business_justification` | text | ✗ | - |
| `requested_start_date` | timestamp with time zone | ✗ | - |
| `requested_end_date` | timestamp with time zone | ✗ | - |
| `created_at` | timestamp with time zone | ✓ | now() |
| `updated_at` | timestamp with time zone | ✓ | now() |
| `admin_notes` | text | ✓ | - |
| `rejection_reason` | text | ✓ | - |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `campaign_id` → `voucher_campaigns.id`
  - `club_id` → `clubs.id`

**Indexes:** 4 indexes

---

### voucher_templates (7 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `template_id` | text | ✗ | - |
| `title` | text | ✗ | - |
| `description` | text | ✗ | - |
| `category` | text | ✗ | - |
| `campaign_type` | text | ✗ | - |
| `target_type` | text | ✗ | - |
| `template_data` | jsonb | ✗ | '{}'::jsonb |
| `is_active` | boolean | ✓ | true |
| `usage_count` | integer | ✓ | 0 |
| `created_at` | timestamp with time zone | ✓ | now() |
| `updated_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Unique:** template_id

**Indexes:** 4 indexes

---

### voucher_usage_history (0 rows)

**Columns:**

| Column | Type | Nullable | Default |
|--------|------|----------|--------|
| `id` | uuid | ✗ | gen_random_uuid() |
| `voucher_id` | uuid | ✗ | - |
| `user_id` | uuid | ✗ | - |
| `club_id` | uuid | ✗ | - |
| `session_id` | text | ✓ | - |
| `original_amount` | numeric | ✓ | - |
| `discount_amount` | numeric | ✓ | - |
| `final_amount` | numeric | ✓ | - |
| `bonus_time_minutes` | integer | ✓ | 0 |
| `additional_benefits` | jsonb | ✓ | '{}'::jsonb |
| `used_at` | timestamp with time zone | ✓ | now() |

**Constraints:**

- **Primary Key:** id
- **Foreign Keys:**
  - `club_id` → `clubs.id`
  - `user_id` → `users.id`
  - `voucher_id` → `user_vouchers.id`

**Indexes:** 5 indexes

---

*Generated by supabase_db_audit.py*
