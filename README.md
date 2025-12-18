# 🏟️ SABO ARENA V3

A modern Flutter-based billiards tournament platform with comprehensive ELO rating system, featuring fixed position-based rewards (10-75 ELO) and 8 different tournament bracket formats.

## 🎯 **NEW FACTORY PATTERN SYSTEM**

**SABO Arena V3** now features a unified tournament system with **Factory Pattern** implementation:
- ✅ **8 Tournament Formats**: Single/Double Elimination, SABO DE16/DE32, Round Robin, Swiss, Parallel Groups, Winner Takes All
- ✅ **Unified Interface**: `BracketServiceFactory` provides consistent API across all formats
- ✅ **99.9% Reliability**: Leverages existing proven services with mathematical advancement formulas
- ✅ **Production Ready**: Successfully tested with real tournament data

📖 **See**: `PROJECT_STRUCTURE.md` for complete project organization
📖 **See**: `docs/tournaments/TOURNAMENT_COMPLETE_GUIDE.md` for usage guide

## 📋 Prerequisites

- Flutter SDK (^3.29.2)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Android SDK / Xcode (for iOS development)

## � Quick Start

### **Development Setup**
1. **Install dependencies**:
```bash
flutter pub get
```

2. **Setup Supabase**: Follow `SUPABASE_INTEGRATION_GUIDE.md`

3. **Setup Environment**:
   - Copy `env.json.example` to `env.json`
   - Fill in your Supabase credentials in `env.json`

4. **Run the App**:
   - **VS Code**: Press `F5` (Launch configuration is already set up!)
   - **Terminal**:
     ```bash
     flutter run --dart-define-from-file=env.json
     ```

### **Quick Test Tournament System**
```bash
# Test tournament creation & advancement
dart scripts/test_scripts/check_tournament_structure.py

# Test factory pattern integration  
flutter test test/test_production_bracket_system.dart
```

### **VS Code Integration**
Use the predefined tasks:
- `Run Flutter App with Supabase`
- `Run Flutter App on Chrome`
- `Run Flutter App on Android Emulator`

### **Production Deployment**
```bash
# Android APK
flutter build apk --release --dart-define-from-file=env.json

# iOS
flutter build ios --release --dart-define-from-file=env.json
```

## 📁 Project Structure

**SABO Arena V3** now features a **professional, organized structure**:

```
SABO_ARENA_V3/
├── 📚 docs/                    # Complete documentation system
│   ├── tournaments/            # Tournament system docs
│   ├── systems/               # System architecture docs  
│   ├── implementation/        # Implementation guides
│   ├── audits/               # System audit reports
│   └── guides/               # Setup & usage guides
├── 🐍 scripts/                # Organized automation tools
│   ├── test_scripts/         # Testing & validation
│   ├── tournament_utils/     # Tournament management
│   ├── database_utils/       # Database operations
│   └── maintenance/          # System maintenance
├── 🎯 lib/                    # Flutter application code
│   ├── core/                 # Core business logic
│   │   ├── interfaces/       # Service interfaces
│   │   └── factories/        # Factory patterns
│   ├── services/             # Business services
│   ├── models/               # Data models
│   ├── screens/              # UI screens
│   ├── widgets/              # UI components
│   ├── utils/                # Utility functions
│   └── debug/                # Debug tools
├── 🧪 test/                   # Flutter test files
├── 📱 android/               # Android configuration
├── 🍎 ios/                   # iOS configuration
├── 📖 PROJECT_STRUCTURE.md   # Complete navigation guide
└── 🗄️ archive/              # Legacy files & backups
```

📖 **For detailed navigation**: See `PROJECT_STRUCTURE.md`

## 🏆 **Tournament Features**

### **Factory Pattern Integration**
```dart
// Easy tournament creation with unified interface
final factory = BracketServiceFactory();
final service = factory.createService('Single Elimination');
final result = await service.processMatch(matchData);
```

### **8 Tournament Formats**
- **Single Elimination**: Classic knockout format
- **Double Elimination**: Winners & losers brackets  
- **SABO DE16**: Custom 16-player double elimination
- **SABO DE32**: Custom 32-player double elimination
- **Round Robin**: Everyone plays everyone
- **Swiss System**: Optimized pairing system
- **Parallel Groups**: Multiple group stages
- **Winner Takes All**: Single final match

### **Advanced Features**
- ✅ **Auto Progression**: Mathematical advancement formulas
- ✅ **ELO Integration**: Position-based rewards (10-75 ELO)
- ✅ **Real-time Updates**: Supabase subscriptions
- ✅ **Admin Controls**: Tournament management interface
- ✅ **Notification System**: Match & tournament alerts

## 🔧 **System Architecture**

### **Core Services**
- `UniversalMatchProgressionService`: Handles all match advancement
- `AutoWinnerDetectionService`: Automatic tournament completion
- `BracketServiceFactory`: Unified tournament interface
- `ELOCalculationService`: Ranking system integration

### **Database & Backend**
- **Supabase PostgreSQL**: Relational data storage
- **Connection**: Transaction Pooler (6543) for database operations
- **Row Level Security**: Multi-tenant access control with custom policies
- **Real-time Subscriptions**: Live updates via WebSocket
- **⚠️ SECURITY**: Database credentials are managed via Supabase dashboard and environment variables
- **Automated Functions**: Tournament progression triggers & RLS bypass functions
## � **Documentation & Support**

### **Key Documentation**
- 📖 `PROJECT_STRUCTURE.md` - Complete project navigation
- 🏆 `docs/tournaments/TOURNAMENT_COMPLETE_GUIDE.md` - Tournament usage
- 🏭 `docs/implementation/FACTORY_PATTERN_IMPLEMENTATION_COMPLETE.md` - Technical details
- 🧪 `docs/guides/MANUAL_TESTING_GUIDE.md` - Testing procedures
- ⚙️ `SUPABASE_INTEGRATION_GUIDE.md` - Complete Supabase setup & troubleshooting
- 🤖 `COPILOT_AUTOMATION.py` - Automated scripts for common tasks

### **Troubleshooting & Maintenance**
```bash
# Database issues
python scripts/database_utils/check_database_matches.py

# Tournament problems  
python scripts/tournament_utils/tournament_analyzer.py

# System health check
dart lib/debug/debug_all_participants.dart
```

### **Development Tools**
- `scripts/test_scripts/` - Validation & testing tools
- `lib/debug/` - Development debugging utilities
- `test/` - Flutter unit & integration tests
- `docs/audits/` - System analysis reports

## 🏅 **Production Status**

✅ **Factory Pattern**: Complete & tested  
✅ **8 Tournament Formats**: All operational  
✅ **ELO System**: Position-based rewards active  
✅ **Admin Features**: Full management interface  
✅ **Real-time Updates**: Supabase integration working  
✅ **Mobile Apps**: Android & iOS ready  

**Last Updated**: October 2025  
**Version**: 3.0 - Factory Pattern Complete  
**Status**: 🚀 Production Ready

---

## 📦 Deployment

```bash
# Production builds
flutter build apk --release --dart-define-from-file=env.json
flutter build ios --release --dart-define-from-file=env.json

# Web deployment  
flutter build web --dart-define-from-file=env.json
```

## 🙏 **Acknowledgments**

- 🏗️ **Architecture**: Expert Tournament System Audit & Factory Pattern Implementation
- 🎯 **Flutter Framework**: [Flutter.dev](https://flutter.dev) & [Dart](https://dart.dev)
- 🗄️ **Backend**: [Supabase](https://supabase.com) - PostgreSQL + Auth + Realtime
- 🎨 **UI/UX**: Material Design 3 + Custom Billiards Theme
- 🧪 **Testing**: Comprehensive test coverage with real tournament data
- 📖 **Documentation**: Professional project structure & guides

**Built with ❤️ for the Billiards Community**  
*Tournament management made simple and reliable*
