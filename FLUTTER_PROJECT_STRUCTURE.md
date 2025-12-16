# SABO Arena Flutter Project Structure

## Overview
This document describes the cleaned and organized Flutter project structure.

## Directory Structure

```
lib/
├── core/               # Core utilities and constants (53 files)
│   ├── constants/      # App-wide constants
│   ├── extensions/     # Dart extensions
│   └── theme/          # Theme configuration
│
├── models/             # Data models (38 files)
│   ├── user/
│   ├── tournament/
│   ├── match/
│   └── ...
│
├── services/           # Business logic layer (169 files)
│   ├── auth/
│   ├── tournament/
│   ├── notification/
│   └── ...
│
├── presentation/       # UI layer - Main screens (328 files)
│   ├── home/
│   ├── profile/
│   ├── tournament/
│   ├── match/
│   └── ...
│
├── widgets/            # Reusable UI components (57 files)
│   ├── buttons/
│   ├── cards/
│   ├── dialogs/
│   └── ...
│
├── utils/              # Helper utilities (19 files)
│   ├── validators/
│   ├── formatters/
│   └── ...
│
├── l10n/               # Localization files (3 files)
│   └── app_localizations.dart
│
├── config/             # App configuration (1 file)
├── theme/              # Theme files (4 files)
└── main.dart           # App entry point
```

## Architectural Pattern

**Clean Architecture with Feature-based Organization**

1. **presentation/** - UI Layer (Screens, Pages, ViewModels)
2. **services/** - Business Logic Layer
3. **models/** - Data Models (Entities)
4. **widgets/** - Reusable UI Components
5. **core/** - Core Utilities, Constants, Extensions

## Archived Folders

The following folders have been archived to \`_ARCHIVED_CODE/\`:
- \`lib/archived/\` - Old archived code
- \`lib/debug/\` - Debug utilities (no longer needed)
- \`lib/test_screens/\` - Test screens (moved to tests)
- \`lib/pages/\` - Consolidated into presentation/
- \`lib/screens/\` - Consolidated into presentation/

## Best Practices

### Adding New Features
1. Create feature folder in \`presentation/\`
2. Add corresponding service in \`services/\`
3. Create models in \`models/\`
4. Use shared widgets from \`widgets/\`

### Naming Conventions
- **Files**: \`snake_case.dart\`
- **Classes**: \`PascalCase\`
- **Variables**: \`camelCase\`
- **Constants**: \`SCREAMING_SNAKE_CASE\`

### Code Organization
- One main class per file
- Keep files under 300 lines
- Extract reusable widgets
- Use meaningful folder names

## Migration Notes

### From Old Structure
If you find references to old paths:
- \`lib/pages/*\` → \`lib/presentation/*\`
- \`lib/screens/*\` → \`lib/presentation/*\`
- \`lib/debug/*\` → Removed (archived)

## Statistics

- **Total Dart Files**: ~686 files
- **Main UI Layer**: 328 files (presentation/)
- **Business Logic**: 169 files (services/)
- **Reusable Widgets**: 57 files (widgets/)
- **Data Models**: 38 files (models/)

---
Generated: 2025-11-22 21:26:39
Last Updated: 2025-11-22
