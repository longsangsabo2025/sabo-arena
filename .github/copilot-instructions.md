# GitHub Copilot Instructions for SABO Arena

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
