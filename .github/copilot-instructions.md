# GitHub Copilot Instructions for SABO Arena

## 🚨 CRITICAL DATABASE PROTOCOL (READ THIS FIRST)
- **PRINCIPLE #1: CHECK LIVE SUPABASE SCHEMA FIRST.**
  - Before assuming a table, column, or RPC is missing, **ALWAYS** verify its existence on the live Supabase instance.
  - Use provided scripts (e.g., `scripts/check_db_state.py`) or create a verification script using credentials from `.env`.
  - **NEVER** write fallback code for "missing" DB features without confirming they are actually missing.

- **NEVER TRUST STATIC MARKDOWN FILES** in `_DATABASE_INFO` (except `LIVE_SCHEMA_SNAPSHOT.md`).
- The database schema changes frequently. Old reports are LIES.
- **Source of Truth**:
  1. Run `dart scripts/get_live_table_count.dart` or python scripts to verify the current schema.
  2. Check `_DATABASE_INFO/LIVE_SCHEMA_SNAPSHOT.md` (if recently updated).
- **Action**: If you need to know if a table exists, CHECK IT LIVE. Do not guess.

## Project Context
SABO Arena is a tournament management platform built with Flutter and Supabase.

## Tech Stack
- **Framework**: Flutter 3.29+, Dart 3.0+
- **Backend**: Supabase PostgreSQL
- **Payment**: VNPAY integration
- **State Management**: Provider/Riverpod

## Code Style Guidelines
- Follow Flutter/Dart style guide
- Use const constructors when possible
- Prefer composition over inheritance
- Use meaningful widget names
- Implement proper error handling

## File Organization
- Screens: `/lib/screens/{feature}/{screen_name}_screen.dart`
- Widgets: `/lib/widgets/{widget_name}.dart`
- Services: `/lib/services/{service_name}_service.dart`
- Models: `/lib/models/{model_name}.dart`
- Utils: `/lib/utils/{util_name}.dart`

## Naming Conventions
- Classes: PascalCase (e.g., `TournamentScreen`)
- Files: snake_case (e.g., `tournament_screen.dart`)
- Variables: camelCase (e.g., `tournamentId`)
- Constants: lowerCamelCase (e.g., `kDefaultPadding`)

## Best Practices
- Use const constructors for performance
- Implement proper lifecycle management
- Add null safety checks
- Use async/await for asynchronous operations
- Implement loading states
- Add proper error messages
- Use keys for list items

## Common Patterns
```dart
// Widget structure
class TournamentCard extends StatelessWidget {
  const TournamentCard({
    Key? key,
    required this.tournament,
  }) : super(key: key);

  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: // Widget tree
    );
  }
}

// Supabase query
final response = await Supabase.instance.client
  .from('tournaments')
  .select()
  .eq('status', 'active')
  .order('created_at');

// Error handling
try {
  await performOperation();
} catch (e) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
```

## Tournament Types
- Single Elimination (8, 16, 32, 64 players)
- Double Elimination with Losers Bracket
- Round Robin
- Swiss System

## ELO Rating System
- Rating updates after each match
- K-factor based on player level
- Proper rating calculation formulas
