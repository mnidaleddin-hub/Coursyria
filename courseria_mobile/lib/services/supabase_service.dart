import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service layer to manage all Supabase operations and connectivity monitoring.
class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  final Connectivity _connectivity = Connectivity();
  
  // Singleton pattern
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  /// 1. Connection Monitoring
  Stream<List<ConnectivityResult>> get onConnectivityChanged => _connectivity.onConnectivityChanged;

  Future<bool> isConnected() async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// --- Comprehensive Comprehensive Tests ---

  /// Generic Insert/Update Test
  Future<Map<String, dynamic>> testUpsert(String table, Map<String, dynamic> data) async {
    try {
      final response = await _client.from(table).upsert(data).select();
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Generic Select Test
  Future<Map<String, dynamic>> testSelect(String table, {String columns = '*', int limit = 5}) async {
    try {
      final response = await _client.from(table).select(columns).limit(limit);
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 2. Database Operations (Legacy Test)
  Future<Map<String, dynamic>> testDatabaseConnection() async {
    return testSelect('courses', columns: 'id, title', limit: 1);
  }

  /// 3. Authentication Operations
  Future<Map<String, dynamic>> testSignUp(String email, String password) async {
    try {
      final response = await _client.auth.signUp(email: email, password: password);
      return {'success': true, 'user': response.user};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 4. Storage Operations (Advanced)
  Future<Map<String, dynamic>> testStorageFullCycle(String bucket, String fileName, String content) async {
    try {
      final bytes = Uint8List.fromList(content.codeUnits);
      // Upload
      await _client.storage.from(bucket).uploadBinary(fileName, bytes, fileOptions: const FileOptions(upsert: true));
      // Get URL
      final String publicUrl = _client.storage.from(bucket).getPublicUrl(fileName);
      // Delete (Cleanup)
      await _client.storage.from(bucket).remove([fileName]);
      
      return {'success': true, 'url': publicUrl};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 5. Realtime Operations
  RealtimeChannel subscribeToTable(String tableName, Function(dynamic) onEvent) {
    // Realtime must be enabled for the table in Supabase Dashboard -> Database -> Replication
    final channel = _client.channel('public:$tableName');
    
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: tableName,
      callback: (payload) {
        debugPrint('🔔 Realtime Event on $tableName: ${payload.toString()}');
        onEvent(payload);
      },
    ).subscribe();
    
    return channel;
  }
}
