import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final url = 'https://mogjjvscxjwvhtpkrlqr.supabase.co';
  final key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo';

  print('🚀 Fetching detailed schema from Supabase...');
  
  final apiUrl = Uri.parse('$url/rest/v1/?apikey=$key');

  try {
    final response = await http.get(apiUrl);

    if (response.statusCode == 200) {
      final Map<String, dynamic> spec = jsonDecode(response.body);
      final definitions = spec['definitions'] as Map<String, dynamic>?;

      if (definitions != null) {
        final Map<String, Map<String, String>> schema = {};

        definitions.forEach((tableName, details) {
          final properties = details['properties'] as Map<String, dynamic>?;
          final columns = <String, String>{};
          
          if (properties != null) {
            properties.forEach((colName, colDetails) {
              columns[colName] = colDetails['type'] ?? 'unknown';
              if (colDetails['format'] != null) {
                 columns[colName] = '${columns[colName]} (${colDetails['format']})';
              }
            });
          }
          schema[tableName] = columns;
        });

        // Save to JSON file
        final file = File('_DATABASE_INFO/LIVE_SCHEMA_DETAILS.json');
        await file.writeAsString(jsonEncode(schema));
        print('✅ Schema details saved to _DATABASE_INFO/LIVE_SCHEMA_DETAILS.json');
        print('📊 Total Tables: ${schema.length}');
      }
    } else {
      print('❌ Failed to fetch schema. Status: ${response.statusCode}');
    }
  } catch (e) {
    print('💥 Exception: $e');
  }
}
