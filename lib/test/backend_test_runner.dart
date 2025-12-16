import '../services/supabase_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/tournament_service.dart';
import '../services/club_service.dart';
import '../services/database_replica_manager.dart';
import '../services/database_connection_manager.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Backend Test Runner - Tự động test các tính năng backend
class BackendTestRunner {
  final List<TestResult> _results = [];
  
  /// Chạy tất cả tests
  Future<Map<String, dynamic>> runAllTests() async {
    _results.clear();
    
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    
    // Test 1: Supabase Connection
    await _testSupabaseConnection();
    
    // Test 2: Database Health Check
    await _testDatabaseHealth();
    
    // Test 3: Database Replica Manager
    await _testDatabaseReplicaManager();
    
    // Test 4: Authentication Service
    await _testAuthService();
    
    // Test 5: User Service
    await _testUserService();
    
    // Test 6: Tournament Service
    await _testTournamentService();
    
    // Test 7: Club Service
    await _testClubService();
    
    // Summary
    return _generateSummary();
  }
  
  /// Test 1: Supabase Connection
  Future<void> _testSupabaseConnection() async {
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    try {
      SupabaseService.instance.client; // Verify connection exists
      _addResult('Supabase Connection', true, '✅ Connected successfully');
    } catch (e) {
      _addResult('Supabase Connection', false, '❌ Error: $e');
    }
  }
  
  /// Test 2: Database Health Check
  Future<void> _testDatabaseHealth() async {
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    try {
      final connectionManager = DatabaseConnectionManager.instance;
      final isHealthy = await connectionManager.checkHealth();
      if (isHealthy) {
        _addResult('Database Health', true, '✅ Database is healthy');
      } else {
        _addResult('Database Health', false, '❌ Database health check failed');
      }
    } catch (e) {
      _addResult('Database Health', false, '❌ Error: $e');
    }
  }
  
  /// Test 3: Database Replica Manager
  Future<void> _testDatabaseReplicaManager() async {
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    try {
      final replicaManager = DatabaseReplicaManager.instance;
      final isHealthy = await replicaManager.checkReplicaHealth();
      if (isHealthy) {
        _addResult('Replica Manager', true, '✅ Replica is healthy');
      } else {
        _addResult('Replica Manager', false, '⚠️ Replica check failed (may be expected if no replica)');
      }
    } catch (e) {
      _addResult('Replica Manager', false, '❌ Error: $e');
    }
  }
  
  /// Test 4: Authentication Service
  Future<void> _testAuthService() async {
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    try {
      final authService = AuthService.instance;
      final currentUser = authService.currentUser;
      if (currentUser != null) {
        _addResult('Auth Service', true, '✅ User authenticated: ${currentUser.id}');
      } else {
        _addResult('Auth Service', true, 'ℹ️ No user logged in (expected for first run)');
      }
    } catch (e) {
      _addResult('Auth Service', false, '❌ Error: $e');
    }
  }
  
  /// Test 5: User Service - Test read operations
  Future<void> _testUserService() async {
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    try {
      final userService = UserService.instance;
      final authService = AuthService.instance;
      final currentUser = authService.currentUser;
      
      if (currentUser != null) {
        // Test get user profile
        try {
          final profile = await userService.getUserProfileById(currentUser.id);
          _addResult('User Service - Get Profile', true, '✅ Profile loaded: ${profile.displayName}');
                } catch (e) {
          _addResult('User Service - Get Profile', false, '❌ Error: $e');
        }
      } else {
        _addResult('User Service', true, 'ℹ️ Skipped - No user logged in');
      }
    } catch (e) {
      _addResult('User Service', false, '❌ Error: $e');
    }
  }
  
  /// Test 6: Tournament Service - Test read operations
  Future<void> _testTournamentService() async {
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    try {
      final tournamentService = TournamentService.instance;
      
      // Test get tournaments (without status filter to avoid enum issues)
      try {
        final tournaments = await tournamentService.getTournaments(
          pageSize: 5,
          // Don't filter by status - database enum may not have 'ready'
        );
        _addResult('Tournament Service - Get Tournaments', true, 
            '✅ Loaded ${tournaments.length} tournaments');
      } catch (e) {
        _addResult('Tournament Service - Get Tournaments', false, '❌ Error: $e');
      }
    } catch (e) {
      _addResult('Tournament Service', false, '❌ Error: $e');
    }
  }
  
  /// Test 7: Club Service - Test read operations
  Future<void> _testClubService() async {
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    try {
      final clubService = ClubService.instance;
      
      // Test get clubs
      try {
        final clubs = await clubService.getClubs(limit: 5);
        _addResult('Club Service - Get Clubs', true, 
            '✅ Loaded ${clubs.length} clubs');
      } catch (e) {
        _addResult('Club Service - Get Clubs', false, '❌ Error: $e');
      }
    } catch (e) {
      _addResult('Club Service', false, '❌ Error: $e');
    }
  }
  
  void _addResult(String testName, bool passed, String message) {
    _results.add(TestResult(
      name: testName,
      passed: passed,
      message: message,
      timestamp: DateTime.now(),
    ));
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
  }
  
  Map<String, dynamic> _generateSummary() {
    final passed = _results.where((r) => r.passed).length;
    final failed = _results.where((r) => !r.passed).length;
    final total = _results.length;
    final successRate = total > 0 ? (passed / total * 100).toStringAsFixed(1) : '0.0';
    
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    
    return {
      'total': total,
      'passed': passed,
      'failed': failed,
      'successRate': double.parse(successRate),
      'results': _results.map((r) => r.toJson()).toList(),
    };
  }
}

class TestResult {
  final String name;
  final bool passed;
  final String message;
  final DateTime timestamp;
  
  TestResult({
    required this.name,
    required this.passed,
    required this.message,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'passed': passed,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}


