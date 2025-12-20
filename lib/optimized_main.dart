import 'package:flutter/material.dart';
import '../presentation/optimized_messaging_screen.dart';
import '../services/optimized_realtime_service.dart';

/// 🚀 TESLA-GRADE App Runner with Optimized Messaging
class OptimizedApp extends StatefulWidget {
  const OptimizedApp({super.key});

  @override
  State<OptimizedApp> createState() => _OptimizedAppState();
}

class _OptimizedAppState extends State<OptimizedApp> {
  final OptimizedRealtimeService _realtimeService = OptimizedRealtimeService();
  // final MessagingService _messagingService = MessagingService.instance; // Unused

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() {
    // Initialize optimized services
    if (mounted) {
      setState(() {
        // Services are ready
      });
    }
  }

  @override
  void dispose() {
    _realtimeService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SABO Arena - Optimized',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const OptimizedHomePage(),
    );
  }
}

class OptimizedHomePage extends StatelessWidget {
  const OptimizedHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚀 SABO Arena - Tesla Optimized'),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
        actions: [
          // Connection status indicator
          StreamBuilder<bool>(
            stream: OptimizedRealtimeService()
                .eventStream
                .where((event) => event.type == RealtimeEventType.connection)
                .map((event) => event.data['status'] == 'connected'),
            builder: (context, snapshot) {
              final isConnected = snapshot.data ?? false;
              return Container(
                margin: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color: isConnected ? Colors.green : Colors.red,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isConnected ? 'LIVE' : 'OFFLINE',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.rocket_launch,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            const Text(
              '🚀 TESLA-GRADE MESSAGING SYSTEM',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Memory Optimized • Smart Caching • Real-time Performance',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Card(
              elevation: 8,
              margin: const EdgeInsets.all(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      '⚡ OPTIMIZATIONS APPLIED:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildOptimizationItem(
                      '🧠 Memory Management',
                      'Single event stream replaces 6+ controllers',
                    ),
                    _buildOptimizationItem(
                      '🔄 Smart Connections',
                      'LRU connection pooling with 5-channel limit',
                    ),
                    _buildOptimizationItem(
                      '📊 Query Performance',
                      'Cursor pagination + separate user cache',
                    ),
                    _buildOptimizationItem(
                      '🛡️ Error Recovery',
                      'Connection timeout + auto-reconnection',
                    ),
                    _buildOptimizationItem(
                      '🗂️ Cache Strategy',
                      'TTL-based cleanup with size limits',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OptimizedMessagingScreen(
                      chatId: 'demo-room-123',
                      chatName: '🚀 Tesla Test Room',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.message),
              label: const Text('TEST OPTIMIZED MESSAGING'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizationItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(
              description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
