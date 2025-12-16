# 🏆 SABO DE24 Tournament Format

## 📊 Overview
**24 players** competing in a two-phase tournament:
1. **Group Stage** (Vòng loại)
2. **Main Stage** (Vòng trong) - DE16 format

---

## 🎯 Phase 1: Group Stage (Vòng Loại)

### Structure
- **8 groups** (A, B, C, D, E, F, G, H)
- **3 players** per group
- **24 players** total

### Format: Round-Robin
Each group plays **3 matches**:
```
Group A:
  Match 1: Player 1 vs Player 2
  Match 2: Player 1 vs Player 3  
  Match 3: Player 2 vs Player 3
```

### Scoring System
- **Win**: 3 points
- **Loss**: 0 points

### Advancement
- **Top 2** from each group advance (16 players total)
- **Bottom 1** from each group eliminated (8 players eliminated)

### Example Group Standings
```
Group A:
  1. Player A1: 2W-0L = 6 points ✅ Advance
  2. Player A2: 1W-1L = 3 points ✅ Advance
  3. Player A3: 0W-2L = 0 points ❌ Eliminated
```

### Total Matches: 24
- 8 groups × 3 matches = **24 matches**

---

## 🏆 Phase 2: Main Stage - DE16 Format

### Structure
**16 qualified players** from group stage

### Format: Double Elimination
- **Winners Bracket**: 16 → 8 → 4 → 2
- **Losers Bracket**: Complex resurrection structure
- **SABO Finals**: Top 4 compete for championship

### Match Flow
```
Winners Bracket:
  Round 1 (WB R1): 16 players → 8 matches → 8 winners
  Round 2 (WB R2): 8 players → 4 matches → 4 winners
  Semi-Finals: 4 players → 2 matches → 2 winners
  
Losers Bracket:
  LB-A R1: 8 losers from WB R1 → 4 matches
  LB-A R2: 4 winners + 4 losers from WB R2 → 2 matches
  LB-A Final: 2 winners → 1 match
  
  LB-B R1: 2 losers from WB Semi → 2 matches
  LB-B Final: Winners compete → 1 match
  
SABO Finals:
  Semi-Final 1: WB winner 1 vs LB-A winner
  Semi-Final 2: WB winner 2 vs LB-B winner
  Grand Finals: SF1 winner vs SF2 winner
```

### Total Matches: 27
- WB: 8 + 4 + 2 = 14 matches
- LB-A: 4 + 2 + 1 = 7 matches
- LB-B: 2 + 1 = 3 matches
- Finals: 2 + 1 = 3 matches
- Total: **27 matches**

---

## 📈 Complete Tournament Stats

### Total Matches: 51
- **Group Stage**: 24 matches
- **Main Stage**: 27 matches

### Player Journey Examples

#### Champion Path (Minimum matches):
```
Group Stage: 2 matches (2-0 record)
Main Stage: 4 matches (4-0 record)
Total: 6 matches minimum
```

#### Runner-up Path (Maximum matches):
```
Group Stage: 2 matches (1-1 record, qualify as 2nd)
Main Stage: 9 matches (lose early, fight through losers bracket)
Total: 11 matches maximum
```

#### Eliminated in Groups:
```
Group Stage: 2 matches (0-2 record)
Total: 2 matches, tournament ends
```

---

## 🎮 Implementation Details

### Match Numbering
```
Group Stage Matches: 1-24
  Group A: Matches 1-3
  Group B: Matches 4-6
  Group C: Matches 7-9
  Group D: Matches 10-12
  Group E: Matches 13-15
  Group F: Matches 16-18
  Group G: Matches 19-21
  Group H: Matches 22-24

Main Stage Matches: 25-51
  WB R1: Matches 25-32 (8 matches)
  WB R2: Matches 33-36 (4 matches)
  WB Semi: Matches 37-38 (2 matches)
  LB-A R1: Matches 39-42 (4 matches)
  LB-A R2: Matches 43-44 (2 matches)
  LB-A Final: Match 45 (1 match)
  LB-B R1: Matches 46-47 (2 matches)
  LB-B Final: Match 48 (1 match)
  SABO SF: Matches 49-50 (2 matches)
  Grand Finals: Match 51 (1 match)
```

### Display Order
```
Group Stage: 1000-1079
  Group A: 1001-1003
  Group B: 1011-1013
  Group C: 1021-1023
  ...
  Group H: 1071-1073

Main Stage: 2100-4201
  WB R1: 2101-2108
  WB R2: 2201-2204
  WB Semi: 2301-2302
  LB-A: 3101-3301
  LB-B: 3401-3501
  Finals: 4101-4201
```

---

## 🔧 Service Usage

### Create Tournament
```dart
final service = HardcodedSaboDE24Service(supabase);

await service.createDE24Tournament(
  tournamentId: 'tournament-id',
  participantIds: [/* 24 player IDs */],
);
```

### Complete Group Stage
```dart
// After all group matches completed
await service.advanceGroupWinnersToMainStage(tournamentId);
```

### Calculate Group Standings
```dart
final topTwo = await service.calculateGroupStandings(
  tournamentId: tournamentId,
  groupName: 'A',
);
```

---

## 🎯 Key Features

### ✅ Automatic
- Random group assignment
- Round-robin match creation
- Standings calculation
- Top 2 advancement

### ✅ Fair Competition
- Equal matches in group stage (everyone plays 2 matches minimum)
- Point-based ranking
- Head-to-head tiebreaker
- Double elimination gives second chances

### ✅ Scalable
- Clear match numbering
- Organized display order
- Metadata tracking
- Easy advancement logic

---

## 📱 UI Display Suggestions

### Group Stage Tab
```
Group A        Group B        Group C        Group D
Player 1 (6)   Player 4 (6)   Player 7 (6)   Player 10 (6)
Player 2 (3)   Player 5 (3)   Player 8 (3)   Player 11 (3)
Player 3 (0)   Player 6 (0)   Player 9 (0)   Player 12 (0)

Group E        Group F        Group G        Group H
Player 13 (6)  Player 16 (6)  Player 19 (6)  Player 22 (6)
Player 14 (3)  Player 17 (3)  Player 20 (3)  Player 23 (3)
Player 15 (0)  Player 18 (0)  Player 21 (0)  Player 24 (0)
```

### Bracket Display
- Use existing SABO DE16 bracket visualization
- Add "Group Qualifiers" section at top
- Show which group each player came from

---

## 🎊 Advantages of DE24

1. **More players**: 24 vs 16 in standard DE16
2. **Fair qualification**: Everyone gets at least 2 matches
3. **Exciting groups**: 3-player round-robin is fast and competitive
4. **Second chances**: DE16 main stage gives losers bracket opportunity
5. **Clear path**: Top performers advance easily, others eliminated fairly

---

## 📝 Notes

- Group assignment is randomized for fairness
- Main stage seeding is also randomized (can be changed to seed by group performance)
- Total tournament time: ~3-4 hours depending on match duration
- Recommended for larger venues with multiple tables

