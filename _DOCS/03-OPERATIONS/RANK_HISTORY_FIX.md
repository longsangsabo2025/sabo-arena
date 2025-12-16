# 🚨 VẤN ĐỀ: Lịch sử Rank không có data

## 📊 HIỆN TRẠNG

### Screen hiện tại:
**File**: `lib/presentation/user_profile_screen/rank_history_screen.dart`

### Query hiện tại (SAI):
```dart
final response = await _supabase
    .from('elo_history')  // ❌ Dùng elo_history
    .select('*')
    .eq('user_id', widget.userId)
    .or('change_reason.eq.rank_promotion,change_reason.eq.rank_demotion')  // ❌ Filter sai
    .order('created_at', ascending: false);
```

### Vấn đề:
1. ❌ **Không có bảng `rank_history`**
2. ❌ `elo_history` không track rank changes (chỉ track ELO)
3. ❌ Không có records nào với `change_reason` = 'rank_promotion' hoặc 'rank_demotion'
4. ✅ `users.rank` column tồn tại nhưng không có history

**Kết quả**: Empty screen - "Chưa có lịch sử thăng/giáng hạng"

---

## ✅ GIẢI PHÁP: Tạo bảng rank_history

### 1️⃣ CREATE TABLE

```sql
-- File: create_rank_history_table.sql
CREATE TABLE IF NOT EXISTS public.rank_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    old_rank TEXT,                     -- Previous rank (NULL for initial)
    new_rank TEXT NOT NULL,            -- New rank after change
    rank_change TEXT NOT NULL,         -- 'promotion', 'demotion', 'initial', 'manual'
    elo_at_change INTEGER,             -- User ELO at time of change
    reason TEXT,                       -- Detailed reason
    tournament_id UUID REFERENCES public.tournaments(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_rank_history_user_id ON public.rank_history(user_id);
CREATE INDEX idx_rank_history_created_at ON public.rank_history(created_at DESC);
CREATE INDEX idx_rank_history_rank_change ON public.rank_history(rank_change);

-- Enable RLS
ALTER TABLE public.rank_history ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view own rank history"
    ON public.rank_history FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Service role can manage rank history"
    ON public.rank_history FOR ALL
    USING (true);
```

### 2️⃣ AUTO-TRIGGER (Track changes automatically)

```sql
-- Trigger to auto-create rank_history when users.rank changes
CREATE OR REPLACE FUNCTION track_rank_changes()
RETURNS TRIGGER AS $$
BEGIN
    -- Only insert if rank actually changed
    IF (OLD.rank IS DISTINCT FROM NEW.rank) THEN
        INSERT INTO public.rank_history (
            user_id,
            old_rank,
            new_rank,
            rank_change,
            elo_at_change,
            reason,
            created_at
        ) VALUES (
            NEW.id,
            OLD.rank,
            NEW.rank,
            CASE
                WHEN OLD.rank IS NULL THEN 'initial'
                WHEN NEW.rank > OLD.rank THEN 'promotion'  -- Assuming higher = better
                WHEN NEW.rank < OLD.rank THEN 'demotion'
                ELSE 'manual'
            END,
            NEW.elo_rating,
            CASE
                WHEN OLD.rank IS NULL THEN 'Initial rank assignment'
                WHEN NEW.rank > OLD.rank THEN format('Promoted from %s to %s', OLD.rank, NEW.rank)
                WHEN NEW.rank < OLD.rank THEN format('Demoted from %s to %s', OLD.rank, NEW.rank)
                ELSE 'Manual rank adjustment'
            END,
            NOW()
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Attach trigger
DROP TRIGGER IF EXISTS trigger_track_rank_changes ON public.users;
CREATE TRIGGER trigger_track_rank_changes
    AFTER UPDATE OF rank ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION track_rank_changes();
```

### 3️⃣ POPULATE INITIAL DATA

```sql
-- Create initial rank_history for existing users
INSERT INTO public.rank_history (
    user_id,
    old_rank,
    new_rank,
    rank_change,
    elo_at_change,
    reason,
    created_at
)
SELECT 
    id as user_id,
    NULL as old_rank,
    rank as new_rank,
    'initial' as rank_change,
    elo_rating as elo_at_change,
    'Initial rank assignment (migrated from existing data)' as reason,
    created_at
FROM public.users
WHERE rank IS NOT NULL
AND id NOT IN (SELECT DISTINCT user_id FROM public.rank_history);

-- Verify
SELECT COUNT(*) FROM public.rank_history;
```

---

## 🔧 UPDATE FLUTTER CODE

### File: `lib/presentation/user_profile_screen/rank_history_screen.dart`

**BEFORE** (Broken):
```dart
Future<void> _loadRankHistory() async {
  try {
    final response = await _supabase
        .from('elo_history')  // ❌ Wrong table
        .select('*')
        .eq('user_id', widget.userId)
        .or('change_reason.eq.rank_promotion,change_reason.eq.rank_demotion')  // ❌ No data
        .order('created_at', ascending: false);

    setState(() {
      _rankHistory = List<Map<String, dynamic>>.from(response);
      _isLoading = false;
    });
  } catch (e) {
    // Error
  }
}
```

**AFTER** (Fixed):
```dart
Future<void> _loadRankHistory() async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    // ✅ Query from rank_history table
    final response = await _supabase
        .from('rank_history')  // ✅ Correct table
        .select('''
          *,
          tournaments:tournament_id (
            name,
            format
          )
        ''')
        .eq('user_id', widget.userId)
        .order('created_at', ascending: false);

    setState(() {
      _rankHistory = List<Map<String, dynamic>>.from(response);
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _errorMessage = 'Lỗi tải lịch sử rank: $e';
      _isLoading = false;
    });
  }
}
```

### Enhanced Display (Like ELO history):

```dart
Widget _buildRankHistoryCard(Map<String, dynamic> record) {
  final oldRank = record['old_rank'] as String?;
  final newRank = record['new_rank'] as String;
  final rankChange = record['rank_change'] as String;
  final eloAtChange = record['elo_at_change'] as int?;
  final reason = record['reason'] as String? ?? '';
  final createdAt = DateTime.parse(record['created_at'] as String);
  final tournament = record['tournaments'] as Map<String, dynamic>?;

  final isPromotion = rankChange == 'promotion';
  final isDemotion = rankChange == 'demotion';
  
  final color = isPromotion ? Colors.green : 
                isDemotion ? Colors.red : 
                Colors.blue;
  
  final icon = isPromotion ? Icons.trending_up :
               isDemotion ? Icons.trending_down :
               Icons.circle;

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.3), width: 1.5),
    ),
    child: Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Row(
            children: [
              // Badge với rank change type
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      isPromotion ? 'Thăng hạng' : 
                      isDemotion ? 'Giáng hạng' : 
                      'Xếp hạng',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Time
              Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                DateFormat('dd/MM HH:mm').format(createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),

        // Body
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reason
              if (reason.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    reason,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Rank change visualization
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    // Old rank
                    Expanded(
                      child: Column(
                        children: [
                          Text('Rank cũ', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          const SizedBox(height: 8),
                          Text(
                            oldRank ?? '-',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),

                    // Arrow
                    Icon(Icons.arrow_forward, size: 24, color: color),

                    // New rank
                    Expanded(
                      child: Column(
                        children: [
                          Text('Rank mới', style: TextStyle(fontSize: 12, color: color)),
                          const SizedBox(height: 8),
                          Text(
                            newRank,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ELO at change
              if (eloAtChange != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.show_chart, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'ELO lúc thay đổi: $eloAtChange',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],

              // Tournament info
              if (tournament != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00695C).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events, size: 16, color: Color(0xFF00695C)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Từ ${tournament['name']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
```

---

## 📊 DATA STRUCTURE

### rank_history table:
```
┌──────────────┬───────────┬──────────┬─────────────┬───────────────┬─────────────────┐
│ id           │ user_id   │ old_rank │ new_rank    │ rank_change   │ elo_at_change   │
├──────────────┼───────────┼──────────┼─────────────┼───────────────┼─────────────────┤
│ uuid-1       │ user-123  │ NULL     │ K           │ initial       │ 1000            │
│ uuid-2       │ user-123  │ K        │ G           │ promotion     │ 1200            │
│ uuid-3       │ user-123  │ G        │ F           │ promotion     │ 1450            │
│ uuid-4       │ user-123  │ F        │ G           │ demotion      │ 1380            │
└──────────────┴───────────┴──────────┴─────────────┴───────────────┴─────────────────┘
```

### rank_change values:
- `initial` - First time rank assigned
- `promotion` - Thăng hạng
- `demotion` - Giáng hạng  
- `manual` - Admin điều chỉnh

---

## 🚀 DEPLOYMENT STEPS

### Step 1: Create table (Supabase Dashboard)
```
1. Go to: https://mogjjvscxjwvhtpkrlqr.supabase.co/project/_/sql
2. Run SQL from create_rank_history_table.sql
3. Verify: SELECT * FROM rank_history LIMIT 1;
```

### Step 2: Create trigger
```
1. Run trigger SQL (track_rank_changes function)
2. Test: UPDATE users SET rank = 'G' WHERE id = 'test-user-id';
3. Verify: SELECT * FROM rank_history WHERE user_id = 'test-user-id';
```

### Step 3: Populate initial data
```
1. Run initial data SQL
2. Verify: SELECT COUNT(*) FROM rank_history;
```

### Step 4: Update Flutter code
```
1. Update rank_history_screen.dart
2. Hot reload app
3. Test: Open "Lịch sử Rank" screen
```

---

## ✅ SUCCESS CRITERIA

After implementation:
- ✅ rank_history table exists with proper schema
- ✅ Trigger automatically tracks rank changes
- ✅ Initial data populated for existing users
- ✅ Screen displays rank history correctly
- ✅ Shows: old rank → new rank, reason, ELO, timestamp
- ✅ Empty state only shows when truly no history

---

## 📝 SUMMARY

**Vấn đề**: Lịch sử Rank empty vì:
1. Không có bảng rank_history
2. Query sai từ elo_history

**Giải pháp**: 
1. Tạo bảng rank_history với trigger auto-track
2. Populate initial data
3. Fix Flutter query để dùng bảng mới
4. Enhanced UI giống ELO history

**Kết quả**: User sẽ thấy lịch sử thăng/giáng hạng chi tiết! 🎉
