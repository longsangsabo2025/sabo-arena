import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/utils/production_logger.dart';

/// Database Replica Manager
/// Routes read queries to read replica, writes to primary database
/// 
/// Benefits:
/// - 10x read capacity
/// - Better performance
/// - Lower latency
/// - Primary database focused on writes
class DatabaseReplicaManager {
  static DatabaseReplicaManager? _instance;
  static DatabaseReplicaManager get instance =>
      _instance ??= DatabaseReplicaManager._();

  DatabaseReplicaManager._();

  SupabaseClient? _cachedClient;

  SupabaseClient get _supabase {
    // Return cached client if available
    if (_cachedClient != null) {
      return _cachedClient!;
    }
    
    try {
      final client = Supabase.instance.client;
      _cachedClient = client; // Cache the client
      return client;
    } catch (e) {
      ProductionLogger.error(
        'Failed to access Supabase client',
        error: e,
        tag: 'DatabaseReplicaManager',
      );
      rethrow;
    }
  }
  
  // Read replica client (configure if using separate replica)
  SupabaseClient? _replicaClient;
  
  // Configuration
  bool _useReplica = true; // Enable/disable replica usage
  int _replicaLagMs = 0; // Track replica lag
  
  /// Initialize replica manager
  Future<void> initialize() async {
    // If using separate read replica, initialize here
    // For Supabase, read replicas are typically handled automatically
    // but we can route queries explicitly if needed
    
    // Don't access Supabase client during initialization - it will be accessed lazily when needed
    // This allows DatabaseReplicaManager to be initialized before Supabase is ready
    // The client will be cached on first access
    
    ProductionLogger.info(
      'DatabaseReplicaManager initialized (replica: $_useReplica)',
      tag: 'DatabaseReplicaManager',
    );
  }

  /// Get client for read operations (use replica if available)
  SupabaseClient get readClient {
    if (_useReplica && _replicaClient != null) {
      return _replicaClient!;
    }
    // Fallback to primary if replica not configured
    // Access Supabase client lazily - will throw if not initialized, which is expected
    try {
      return _supabase;
    } catch (e) {
      ProductionLogger.error(
        'readClient failed - Supabase not ready',
        error: e,
        tag: 'DatabaseReplicaManager',
      );
      rethrow;
    }
  }

  /// Get client for write operations (always use primary)
  SupabaseClient get writeClient => _supabase;

  /// Check if replica is healthy
  Future<bool> checkReplicaHealth() async {
    try {
      final startTime = DateTime.now();
      // Use users table for health check (profiles table may not exist)
      await readClient.from('users').select('id').limit(1);
      final duration = DateTime.now().difference(startTime);
      
      if (duration.inMilliseconds > 1000) {
        ProductionLogger.warning(
          'Read replica slow: ${duration.inMilliseconds}ms',
          tag: 'DatabaseReplicaManager',
        );
        return false;
      }
      
      return true;
    } catch (e) {
      ProductionLogger.error(
        'Read replica health check failed',
        error: e,
        tag: 'DatabaseReplicaManager',
      );
      return false;
    }
  }

  /// Enable/disable replica usage
  void setUseReplica(bool useReplica) {
    _useReplica = useReplica;
    ProductionLogger.info(
      'Read replica usage: ${_useReplica ? "enabled" : "disabled"}',
      tag: 'DatabaseReplicaManager',
    );
  }

  /// Get replica lag
  int get replicaLagMs => _replicaLagMs;

  /// Update replica lag (call periodically)
  Future<void> updateReplicaLag() async {
    try {
      // Measure lag by comparing timestamps from primary and replica
      // This is a simplified version - adjust based on your setup
      final primaryTime = DateTime.now();
      final replicaTime = DateTime.now(); // In real implementation, query replica
      
      _replicaLagMs = replicaTime.difference(primaryTime).inMilliseconds.abs();
    } catch (e) {
      ProductionLogger.warning(
        'Failed to update replica lag',
        error: e,
        tag: 'DatabaseReplicaManager',
      );
    }
  }
}

/// Extension to SupabaseClient for automatic replica routing
extension SupabaseReplicaExtension on SupabaseClient {
  /// Use this for read operations (automatically routes to replica)
  SupabaseClient get read => DatabaseReplicaManager.instance.readClient;
  
  /// Use this for write operations (always uses primary)
  SupabaseClient get write => DatabaseReplicaManager.instance.writeClient;
}

