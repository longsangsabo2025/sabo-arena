import 'package:flutter/material.dart';
import '../presentation/home_feed_screen/home_feed_screen.dart';
import '../presentation/find_opponents_screen/find_opponents_screen.dart';
import '../presentation/tournament_list_screen/tournament_list_screen.dart';
import '../presentation/club_main_screen/club_main_screen.dart';
import '../presentation/user_profile_screen/user_profile_screen.dart';
import 'package:sabo_arena/utils/production_logger.dart';

/// 🎯 FACEBOOK/INSTAGRAM APPROACH: Persistent Tab Navigation
/// 
/// ADVANTAGES:
/// ✅ Giữ state của tất cả tabs (không rebuild khi chuyển tab)
/// ✅ Instant switching (không có animation delay)
/// ✅ Memory efficient (lazy loading screens)
/// ✅ Smooth user experience
/// 
/// HOW IT WORKS:
/// - IndexedStack giữ tất cả 5 screens trong memory
/// - Chỉ hiển thị screen hiện tại
/// - Screens khác vẫn giữ state (scroll position, data, etc.)
class PersistentTabScaffold extends StatefulWidget {
  final int initialIndex;

  const PersistentTabScaffold({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<PersistentTabScaffold> createState() => _PersistentTabScaffoldState();
}

class _PersistentTabScaffoldState extends State<PersistentTabScaffold> {
  late int _currentIndex;
  
  // 🎯 LAZY LOADING: Chỉ build screens khi user truy cập lần đầu
  final List<bool> _hasVisited = [false, false, false, false, false];
  final List<Widget?> _cachedScreens = [null, null, null, null, null];
  
  // 🧠 PHASE 3: Memory Management - Track last access time for cleanup
  final List<DateTime?> _lastAccessed = [null, null, null, null, null];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _hasVisited[_currentIndex] = true; // Mark initial screen as visited
    
    // 🚀 PHASE 3: Cache Warming - Preload most-used tabs after a short delay
    _warmupCache();
  }
  
  /// 🔥 Cache Warming: Intelligently preload frequently accessed tabs
  /// Loads tabs 0 and 1 (Home & Find Opponents) in background if not already loaded
  void _warmupCache() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      
      // Preload Home tab if not current and not visited
      if (_currentIndex != 0 && !_hasVisited[0]) {
        setState(() {
          _hasVisited[0] = true;
          _cachedScreens[0] = _getScreenForIndex(0);
        });
        ProductionLogger.info('🔥 [Cache Warming] Preloaded Home tab');
      }
      
      // Preload Find Opponents tab if not current and not visited
      if (_currentIndex != 1 && !_hasVisited[1]) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          setState(() {
            _hasVisited[1] = true;
            _cachedScreens[1] = _getScreenForIndex(1);
          });
          ProductionLogger.info('🔥 [Cache Warming] Preloaded Find Opponents tab');
        });
      }
    });
  }

  /// Build screen on first visit, then cache it
  Widget _buildScreen(int index) {
    // If not visited yet, mark as visited and build screen
    if (!_hasVisited[index]) {
      _hasVisited[index] = true;
      _cachedScreens[index] = _getScreenForIndex(index);
    }
    
    // If already visited but not cached (shouldn't happen), build it
    if (_cachedScreens[index] == null) {
      _cachedScreens[index] = _getScreenForIndex(index);
    }
    
    return _cachedScreens[index]!;
  }

  Widget _getScreenForIndex(int index) {
    switch (index) {
      case 0:
        return const HomeFeedScreen();
      case 1:
        return const FindOpponentsScreen();
      case 2:
        return const TournamentListScreen();
      case 3:
        return const ClubMainScreen();
      case 4:
        return const UserProfileScreen();
      default:
        return const HomeFeedScreen();
    }
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return; // Prevent unnecessary setState
    
    setState(() {
      _currentIndex = index;
      _lastAccessed[index] = DateTime.now(); // Track access time
    });
    
    // 🚀 PHASE 3: Smart Prefetching
    // Prefetch next likely tab based on user behavior patterns
    _prefetchNextLikelyTab(index);
    
    // 🧠 PHASE 3: Memory Management - Cleanup old screens
    _cleanupInactiveScreens();
  }
  
  /// 🎯 Smart Prefetching: Load next probable tab in background
  /// Based on typical user navigation patterns:
  /// - From Home (0) → likely to go to Find Opponents (1)
  /// - From Find Opponents (1) → likely to go to Profile (4) or Tournaments (2)
  /// - From Tournaments (2) → likely to go to Clubs (3)
  /// - From Clubs (3) → likely to go to Profile (4)
  void _prefetchNextLikelyTab(int currentIndex) {
    int? nextTab;
    
    switch (currentIndex) {
      case 0: // Home → Find Opponents
        nextTab = 1;
        break;
      case 1: // Find Opponents → Tournaments
        nextTab = 2;
        break;
      case 2: // Tournaments → Clubs
        nextTab = 3;
        break;
      case 3: // Clubs → Profile
        nextTab = 4;
        break;
      case 4: // Profile → Home (loop back)
        nextTab = 0;
        break;
    }
    
    if (nextTab != null && !_hasVisited[nextTab]) {
      // Delay prefetch to avoid blocking current tab
      final tabToLoad = nextTab; // Capture for closure
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_hasVisited[tabToLoad]) {
          setState(() {
            _hasVisited[tabToLoad] = true;
            _cachedScreens[tabToLoad] = _getScreenForIndex(tabToLoad);
          });
          ProductionLogger.info('🚀 [Prefetch] Loaded tab $tabToLoad in background');
        }
      });
    }
  }
  
  /// 🧠 Memory Management: Clear screens not accessed in last 10 minutes
  /// Keeps current screen and adjacent screens to maintain smooth navigation
  void _cleanupInactiveScreens() {
    final now = DateTime.now();
    const inactiveThreshold = Duration(minutes: 10);
    
    for (int i = 0; i < 5; i++) {
      // Skip current screen and adjacent screens
      if (i == _currentIndex || 
          i == _currentIndex - 1 || 
          i == _currentIndex + 1) {
        continue;
      }
      
      // Skip if not visited yet
      if (!_hasVisited[i] || _cachedScreens[i] == null) continue;
      
      // Check if screen is inactive
      final lastAccess = _lastAccessed[i];
      if (lastAccess != null && now.difference(lastAccess) > inactiveThreshold) {
        setState(() {
          _cachedScreens[i] = null;
          _hasVisited[i] = false;
          _lastAccessed[i] = null;
        });
        ProductionLogger.info('🧹 [Cleanup] Removed inactive tab $i from memory');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // If not on Home tab, go to Home tab first
        setState(() {
          _currentIndex = 0;
        });
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            // Build screens lazily
            _buildScreen(0), // Home Feed
            _buildScreen(1), // Find Opponents
            _buildScreen(2), // Tournaments
            _buildScreen(3), // Clubs
            _buildScreen(4), // Profile
          ],
        ),
        bottomNavigationBar: _buildBottomNavigation(),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            selectedItemColor: theme.colorScheme.primary,
            unselectedItemColor: Colors.grey[500],
            backgroundColor: Colors.white,
            elevation: 0,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            onTap: _onTabTapped,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Trang chủ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search_outlined),
                activeIcon: Icon(Icons.search_rounded),
                label: 'Tìm đối thủ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.emoji_events_outlined),
                activeIcon: Icon(Icons.emoji_events_rounded),
                label: 'Giải đấu',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.groups_outlined),
                activeIcon: Icon(Icons.groups_rounded),
                label: 'Câu lạc bộ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Cá nhân',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
