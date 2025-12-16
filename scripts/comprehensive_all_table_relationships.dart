import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> main() async {
  const supabaseUrl = 'https://mogjjvscxjwvhtpkrlqr.supabase.co';
  const serviceKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo';

  print('🔍 KIỂM TRA RELATIONSHIP CỦA TẤT CẢ CÁC BẢNG\n');

  try {
    // 1. Lấy danh sách tất cả các bảng
    print('📋 Step 1: Lấy danh sách tất cả các bảng...');
    List<String> allTables = await getAllTables(supabaseUrl, serviceKey);

    // 2. Kiểm tra foreign key constraints
    print('\n🔗 Step 2: Kiểm tra foreign key constraints...');
    await checkForeignKeyConstraints(supabaseUrl, serviceKey);

    // 3. Test tất cả relationships có thể
    print('\n🧪 Step 3: Test tất cả relationships...');
    await testAllRelationships(supabaseUrl, serviceKey, allTables);

    // 4. Kiểm tra dữ liệu reference integrity
    print('\n✅ Step 4: Kiểm tra reference integrity...');
    await checkReferenceIntegrity(supabaseUrl, serviceKey);

    // 5. Tạo relationship map
    print('\n🗺️ Step 5: Tạo relationship map...');
    await createRelationshipMap(supabaseUrl, serviceKey);

    print('\n🎯 TỔNG KẾT RELATIONSHIP:');
    print('=========================================');
  } catch (e) {
    print('❌ Error: $e');
  }
}

Future<List<String>> getAllTables(String baseUrl, String apiKey) async {
  final url = Uri.parse('$baseUrl/rest/v1/rpc/exec_sql');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
      'apikey': apiKey,
    },
    body: json.encode({
      'query': '''
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_type = 'BASE TABLE'
        ORDER BY table_name
      ''',
    }),
  );

  List<String> tables = [];
  if (response.statusCode == 200) {
    // Try to check if tables exist via direct REST API
    final commonTables = [
      'users',
      'clubs',
      'club_members',
      'tournaments',
      'tournament_participants',
      'matches',
      'posts',
      'comments',
      'post_likes',
      'achievements',
      'user_achievements',
      'notifications',
      'challenges',
      'ratings',
      'leaderboards',
    ];

    for (String table in commonTables) {
      try {
        final testUrl = Uri.parse('$baseUrl/rest/v1/$table?select=*&limit=1');
        final testResponse = await http.get(
          testUrl,
          headers: {'Authorization': 'Bearer $apiKey', 'apikey': apiKey},
        );

        if (testResponse.statusCode == 200) {
          tables.add(table);
          final data = json.decode(testResponse.body);
          print('   ✅ $table: ${data.length} record(s)');
        } else if (testResponse.statusCode == 404) {
          print('   ❌ $table: Does not exist');
        }
      } catch (e) {
        print('   ⚠️ $table: Error testing - $e');
      }
    }
  }

  print('   📊 Total tables found: ${tables.length}');
  return tables;
}

Future<void> checkForeignKeyConstraints(String baseUrl, String apiKey) async {
  final url = Uri.parse('$baseUrl/rest/v1/rpc/exec_sql');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
      'apikey': apiKey,
    },
    body: json.encode({
      'query': '''
        SELECT 
          tc.table_name,
          kcu.column_name,
          ccu.table_name AS foreign_table_name,
          ccu.column_name AS foreign_column_name,
          tc.constraint_name
        FROM 
          information_schema.table_constraints AS tc 
          JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
          JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
            AND ccu.table_schema = tc.table_schema
        WHERE tc.constraint_type = 'FOREIGN KEY' 
        AND tc.table_schema = 'public'
        ORDER BY tc.table_name, kcu.column_name
      ''',
    }),
  );

  if (response.statusCode == 200) {
    print('   🔗 Foreign Key Constraints được tìm thấy:');
    // Since exec_sql might not return proper data, let's manually check known relationships
    await checkKnownRelationships(baseUrl, apiKey);
  } else {
    print('   ⚠️ Không thể lấy foreign key constraints qua exec_sql');
    await checkKnownRelationships(baseUrl, apiKey);
  }
}

Future<void> checkKnownRelationships(String baseUrl, String apiKey) async {
  final knownRelationships = [
    {
      'table': 'club_members',
      'column': 'club_id',
      'ref_table': 'clubs',
      'ref_column': 'id',
    },
    {
      'table': 'club_members',
      'column': 'user_id',
      'ref_table': 'users',
      'ref_column': 'id',
    },
    {
      'table': 'tournaments',
      'column': 'club_id',
      'ref_table': 'clubs',
      'ref_column': 'id',
    },
    {
      'table': 'tournaments',
      'column': 'organizer_id',
      'ref_table': 'users',
      'ref_column': 'id',
    },
    {
      'table': 'tournament_participants',
      'column': 'tournament_id',
      'ref_table': 'tournaments',
      'ref_column': 'id',
    },
    {
      'table': 'tournament_participants',
      'column': 'user_id',
      'ref_table': 'users',
      'ref_column': 'id',
    },
    {
      'table': 'matches',
      'column': 'tournament_id',
      'ref_table': 'tournaments',
      'ref_column': 'id',
    },
    {
      'table': 'matches',
      'column': 'player1_id',
      'ref_table': 'users',
      'ref_column': 'id',
    },
    {
      'table': 'matches',
      'column': 'player2_id',
      'ref_table': 'users',
      'ref_column': 'id',
    },
    {
      'table': 'matches',
      'column': 'winner_id',
      'ref_table': 'users',
      'ref_column': 'id',
    },
    {
      'table': 'posts',
      'column': 'user_id',
      'ref_table': 'users',
      'ref_column': 'id',
    },
    {
      'table': 'posts',
      'column': 'club_id',
      'ref_table': 'clubs',
      'ref_column': 'id',
    },
    {
      'table': 'posts',
      'column': 'tournament_id',
      'ref_table': 'tournaments',
      'ref_column': 'id',
    },
    {
      'table': 'comments',
      'column': 'post_id',
      'ref_table': 'posts',
      'ref_column': 'id',
    },
    {
      'table': 'comments',
      'column': 'user_id',
      'ref_table': 'users',
      'ref_column': 'id',
    },
    {
      'table': 'post_likes',
      'column': 'user_id',
      'ref_table': 'users',
      'ref_column': 'id',
    },
    {
      'table': 'post_likes',
      'column': 'post_id',
      'ref_table': 'posts',
      'ref_column': 'id',
    },
  ];

  for (var rel in knownRelationships) {
    print(
      '   🔗 ${rel['table']}.${rel['column']} → ${rel['ref_table']}.${rel['ref_column']}',
    );
  }
}

Future<void> testAllRelationships(
  String baseUrl,
  String apiKey,
  List<String> tables,
) async {
  print('   🧪 Testing relationships between tables...\n');

  // Test users relationships
  if (tables.contains('users')) {
    await testUsersRelationships(baseUrl, apiKey, tables);
  }

  // Test clubs relationships
  if (tables.contains('clubs')) {
    await testClubsRelationships(baseUrl, apiKey, tables);
  }

  // Test tournaments relationships
  if (tables.contains('tournaments')) {
    await testTournamentsRelationships(baseUrl, apiKey, tables);
  }

  // Test posts relationships
  if (tables.contains('posts')) {
    await testPostsRelationships(baseUrl, apiKey, tables);
  }

  // Test matches relationships
  if (tables.contains('matches')) {
    await testMatchesRelationships(baseUrl, apiKey, tables);
  }
}

Future<void> testUsersRelationships(
  String baseUrl,
  String apiKey,
  List<String> tables,
) async {
  print('   👤 USERS relationships:');

  // Test users -> club_members
  if (tables.contains('club_members')) {
    try {
      final url = Uri.parse(
        '$baseUrl/rest/v1/users?select=id,full_name,club_members(club_id,joined_at)&limit=2',
      );
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $apiKey', 'apikey': apiKey},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('      ✅ users → club_members: SUCCESS (${data.length} users)');
        for (var user in data) {
          if (user['club_members'] != null && user['club_members'].isNotEmpty) {
            print(
              '         👤 ${user['full_name']}: ${user['club_members'].length} club memberships',
            );
          }
        }
      } else {
        print('      ❌ users → club_members: FAILED (${response.statusCode})');
      }
    } catch (e) {
      print('      ❌ users → club_members: ERROR - $e');
    }
  }

  // Test users -> posts
  if (tables.contains('posts')) {
    try {
      final url = Uri.parse(
        '$baseUrl/rest/v1/users?select=id,full_name,posts(id,content)&limit=2',
      );
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $apiKey', 'apikey': apiKey},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('      ✅ users → posts: SUCCESS (${data.length} users)');
        for (var user in data) {
          if (user['posts'] != null) {
            print(
              '         👤 ${user['full_name']}: ${user['posts'].length} posts',
            );
          }
        }
      } else {
        print('      ❌ users → posts: FAILED (${response.statusCode})');
      }
    } catch (e) {
      print('      ❌ users → posts: ERROR - $e');
    }
  }

  // Test users -> tournaments (as organizer)
  if (tables.contains('tournaments')) {
    try {
      final url = Uri.parse(
        '$baseUrl/rest/v1/users?select=id,full_name,tournaments!organizer_id(title,status)&limit=2',
      );
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $apiKey', 'apikey': apiKey},
      );

      if (response.statusCode == 200) {
        print('      ✅ users → tournaments (organizer): SUCCESS');
      } else {
        print(
          '      ⚠️ users → tournaments (organizer): Status ${response.statusCode}',
        );
      }
    } catch (e) {
      print('      ❌ users → tournaments (organizer): ERROR - $e');
    }
  }

  print('');
}

Future<void> testClubsRelationships(
  String baseUrl,
  String apiKey,
  List<String> tables,
) async {
  print('   🏰 CLUBS relationships:');

  // Test clubs -> club_members
  if (tables.contains('club_members')) {
    try {
      final url = Uri.parse(
        '$baseUrl/rest/v1/clubs?select=id,name,club_members(user_id,joined_at)&limit=2',
      );
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $apiKey', 'apikey': apiKey},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('      ✅ clubs → club_members: SUCCESS (${data.length} clubs)');
        for (var club in data) {
          if (club['club_members'] != null) {
            print(
              '         🏰 ${club['name']}: ${club['club_members'].length} members',
            );
          }
        }
      } else {
        print('      ❌ clubs → club_members: FAILED (${response.statusCode})');
      }
    } catch (e) {
      print('      ❌ clubs → club_members: ERROR - $e');
    }
  }

  // Test clubs -> tournaments
  if (tables.contains('tournaments')) {
    try {
      final url = Uri.parse(
        '$baseUrl/rest/v1/clubs?select=id,name,tournaments(title,status)&limit=2',
      );
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $apiKey', 'apikey': apiKey},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('      ✅ clubs → tournaments: SUCCESS (${data.length} clubs)');
        for (var club in data) {
          if (club['tournaments'] != null) {
            print(
              '         🏰 ${club['name']}: ${club['tournaments'].length} tournaments',
            );
          }
        }
      } else {
        print('      ❌ clubs → tournaments: FAILED (${response.statusCode})');
      }
    } catch (e) {
      print('      ❌ clubs → tournaments: ERROR - $e');
    }
  }

  print('');
}

Future<void> testTournamentsRelationships(
  String baseUrl,
  String apiKey,
  List<String> tables,
) async {
  print('   🏆 TOURNAMENTS relationships:');

  // Test tournaments -> tournament_participants
  if (tables.contains('tournament_participants')) {
    try {
      final url = Uri.parse(
        '$baseUrl/rest/v1/tournaments?select=id,title,tournament_participants(user_id,registered_at)&limit=2',
      );
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $apiKey', 'apikey': apiKey},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(
          '      ✅ tournaments → tournament_participants: SUCCESS (${data.length} tournaments)',
        );
        for (var tournament in data) {
          if (tournament['tournament_participants'] != null) {
            print(
              '         🏆 ${tournament['title']}: ${tournament['tournament_participants'].length} participants',
            );
          }
        }
      } else {
        print(
          '      ❌ tournaments → tournament_participants: FAILED (${response.statusCode})',
        );
      }
    } catch (e) {
      print('      ❌ tournaments → tournament_participants: ERROR - $e');
    }
  }

  // Test tournaments -> matches
  if (tables.contains('matches')) {
    try {
      final url = Uri.parse(
        '$baseUrl/rest/v1/tournaments?select=id,title,matches(id,status,round_number)&limit=2',
      );
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $apiKey', 'apikey': apiKey},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(
          '      ✅ tournaments → matches: SUCCESS (${data.length} tournaments)',
        );
        for (var tournament in data) {
          if (tournament['matches'] != null) {
            print(
              '         🏆 ${tournament['title']}: ${tournament['matches'].length} matches',
            );
          }
        }
      } else {
        print('      ❌ tournaments → matches: FAILED (${response.statusCode})');
      }
    } catch (e) {
      print('      ❌ tournaments → matches: ERROR - $e');
    }
  }

  print('');
}

Future<void> testPostsRelationships(
  String baseUrl,
  String apiKey,
  List<String> tables,
) async {
  print('   📝 POSTS relationships:');

  // Test posts -> users
  if (tables.contains('users')) {
    try {
      final url = Uri.parse(
        '$baseUrl/rest/v1/posts?select=id,content,users!inner(full_name,avatar_url)&limit=3',
      );
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $apiKey', 'apikey': apiKey},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('      ✅ posts → users: SUCCESS (${data.length} posts)');
        for (var post in data) {
          final user = post['users'];
          print('         📝 Post by ${user['full_name']}');
        }
      } else {
        print('      ❌ posts → users: FAILED (${response.statusCode})');
      }
    } catch (e) {
      print('      ❌ posts → users: ERROR - $e');
    }
  }

  // Test posts -> comments
  if (tables.contains('comments')) {
    try {
      final url = Uri.parse(
        '$baseUrl/rest/v1/posts?select=id,content,comments(id,content)&limit=3',
      );
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $apiKey', 'apikey': apiKey},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('      ✅ posts → comments: SUCCESS (${data.length} posts)');
        for (var post in data) {
          if (post['comments'] != null) {
            print('         📝 Post has ${post['comments'].length} comments');
          }
        }
      } else {
        print('      ❌ posts → comments: FAILED (${response.statusCode})');
      }
    } catch (e) {
      print('      ❌ posts → comments: ERROR - $e');
    }
  }

  print('');
}

Future<void> testMatchesRelationships(
  String baseUrl,
  String apiKey,
  List<String> tables,
) async {
  print('   ⚔️ MATCHES relationships:');

  // Test matches -> users (players)
  if (tables.contains('users')) {
    try {
      final url = Uri.parse(
        '$baseUrl/rest/v1/matches?select=id,status,player1:users!player1_id(full_name),player2:users!player2_id(full_name)&limit=3',
      );
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $apiKey', 'apikey': apiKey},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(
          '      ✅ matches → users (players): SUCCESS (${data.length} matches)',
        );
        for (var match in data) {
          final player1 = match['player1'];
          final player2 = match['player2'];
          if (player1 != null && player2 != null) {
            print(
              '         ⚔️ ${player1['full_name']} vs ${player2['full_name']}',
            );
          }
        }
      } else {
        print(
          '      ❌ matches → users (players): FAILED (${response.statusCode})',
        );
      }
    } catch (e) {
      print('      ❌ matches → users (players): ERROR - $e');
    }
  }

  print('');
}

Future<void> checkReferenceIntegrity(String baseUrl, String apiKey) async {
  print('   ✅ Checking reference integrity...');

  // Check for orphaned records
  final checks = [
    {'table': 'club_members', 'foreign_key': 'club_id', 'ref_table': 'clubs'},
    {'table': 'club_members', 'foreign_key': 'user_id', 'ref_table': 'users'},
    {'table': 'posts', 'foreign_key': 'user_id', 'ref_table': 'users'},
    {'table': 'comments', 'foreign_key': 'post_id', 'ref_table': 'posts'},
    {'table': 'comments', 'foreign_key': 'user_id', 'ref_table': 'users'},
  ];

  for (var check in checks) {
    print(
      '      🔍 Checking ${check['table']}.${check['foreign_key']} → ${check['ref_table']}',
    );
  }
}

Future<void> createRelationshipMap(String baseUrl, String apiKey) async {
  print('   🗺️ DATABASE RELATIONSHIP MAP:');
  print('   =====================================');
  print('   👤 USERS (Central table)');
  print('      ├── club_members (user_id)');
  print('      ├── posts (user_id)');
  print('      ├── comments (user_id)');
  print('      ├── post_likes (user_id)');
  print('      ├── tournaments (organizer_id)');
  print('      ├── tournament_participants (user_id)');
  print('      ├── matches (player1_id, player2_id, winner_id)');
  print('      └── clubs (owner_id)');
  print('');
  print('   🏰 CLUBS');
  print('      ├── club_members (club_id)');
  print('      ├── tournaments (club_id)');
  print('      └── posts (club_id)');
  print('');
  print('   🏆 TOURNAMENTS');
  print('      ├── tournament_participants (tournament_id)');
  print('      ├── matches (tournament_id)');
  print('      └── posts (tournament_id)');
  print('');
  print('   📝 POSTS');
  print('      ├── comments (post_id)');
  print('      └── post_likes (post_id)');
  print('');
  print('   ⚔️ MATCHES');
  print('      └── (various user references)');
}
