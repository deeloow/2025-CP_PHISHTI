
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user.dart' as app_user;

class SupabaseDatabaseService {
  static final SupabaseDatabaseService _instance = SupabaseDatabaseService._internal();
  static SupabaseDatabaseService get instance => _instance;
  
  SupabaseDatabaseService._internal();
  
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // User operations
  Future<app_user.AppUser?> getUser(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      
      return app_user.AppUser.fromJson(response);
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }
  
  Future<void> createUser(app_user.AppUser user) async {
    try {
      await _supabase.from('users').insert(user.toJson());
    } catch (e) {
      print('Error creating user: $e');
      throw Exception('Failed to create user: $e');
    }
  }
  
  Future<void> updateUser(app_user.AppUser user) async {
    try {
      await _supabase
          .from('users')
          .update(user.toJson())
          .eq('id', user.id);
    } catch (e) {
      print('Error updating user: $e');
      throw Exception('Failed to update user: $e');
    }
  }
  
  Future<void> deleteUser(String userId) async {
    try {
      await _supabase.from('users').delete().eq('id', userId);
    } catch (e) {
      print('Error deleting user: $e');
      throw Exception('Failed to delete user: $e');
    }
  }
  
  // SMS Analysis operations
  Future<void> saveSmsAnalysis(Map<String, dynamic> analysis) async {
    try {
      await _supabase.from('sms_analyses').insert(analysis);
    } catch (e) {
      print('Error saving SMS analysis: $e');
      throw Exception('Failed to save SMS analysis: $e');
    }
  }
  
  Future<List<Map<String, dynamic>>> getSmsAnalyses(String userId, {int limit = 50}) async {
    try {
      final response = await _supabase
          .from('sms_analyses')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting SMS analyses: $e');
      return [];
    }
  }
  
  Future<void> deleteSmsAnalysis(String analysisId) async {
    try {
      await _supabase.from('sms_analyses').delete().eq('id', analysisId);
    } catch (e) {
      print('Error deleting SMS analysis: $e');
      throw Exception('Failed to delete SMS analysis: $e');
    }
  }
  
  // Phishing Detection operations
  Future<void> savePhishingDetection(Map<String, dynamic> detection) async {
    try {
      await _supabase.from('phishing_detections').insert(detection);
    } catch (e) {
      print('Error saving phishing detection: $e');
      throw Exception('Failed to save phishing detection: $e');
    }
  }
  
  Future<List<Map<String, dynamic>>> getPhishingDetections(String userId, {int limit = 50}) async {
    try {
      final response = await _supabase
          .from('phishing_detections')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting phishing detections: $e');
      return [];
    }
  }
  
  // ML Model operations
  Future<void> saveMLModel(Map<String, dynamic> model) async {
    try {
      await _supabase.from('ml_models').insert(model);
    } catch (e) {
      print('Error saving ML model: $e');
      throw Exception('Failed to save ML model: $e');
    }
  }
  
  Future<Map<String, dynamic>?> getLatestMLModel() async {
    try {
      final response = await _supabase
          .from('ml_models')
          .select()
          .order('created_at', ascending: false)
          .limit(1)
          .single();
      
      return response;
    } catch (e) {
      print('Error getting latest ML model: $e');
      return null;
    }
  }
  
  // Statistics operations
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      // Get SMS analysis count
      final smsCount = await _supabase
          .from('sms_analyses')
          .select('id')
          .eq('user_id', userId);
      
      // Get phishing detection count
      final phishingCount = await _supabase
          .from('phishing_detections')
          .select('id')
          .eq('user_id', userId);
      
      // Get high-risk detections count
      final highRiskCount = await _supabase
          .from('phishing_detections')
          .select('id')
          .eq('user_id', userId)
          .eq('risk_level', 'high');
      
      return {
        'total_sms_analyses': smsCount.length,
        'total_phishing_detections': phishingCount.length,
        'high_risk_detections': highRiskCount.length,
      };
    } catch (e) {
      print('Error getting user stats: $e');
      return {
        'total_sms_analyses': 0,
        'total_phishing_detections': 0,
        'high_risk_detections': 0,
      };
    }
  }
  
  // Real-time subscriptions
  RealtimeChannel subscribeToUserUpdates(String userId, Function(Map<String, dynamic>) onUpdate) {
    return _supabase
        .channel('user_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'users',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (payload) {
            onUpdate(payload.newRecord);
          },
        )
        .subscribe();
  }
  
  RealtimeChannel subscribeToSmsAnalyses(String userId, Function(Map<String, dynamic>) onUpdate) {
    return _supabase
        .channel('sms_analyses')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'sms_analyses',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            onUpdate(payload.newRecord);
          },
        )
        .subscribe();
  }
  
  // Cleanup operations
  Future<void> cleanupOldData(String userId, {int daysOld = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      // Delete old SMS analyses
      await _supabase
          .from('sms_analyses')
          .delete()
          .eq('user_id', userId)
          .lt('created_at', cutoffDate.toIso8601String());
      
      // Delete old phishing detections
      await _supabase
          .from('phishing_detections')
          .delete()
          .eq('user_id', userId)
          .lt('created_at', cutoffDate.toIso8601String());
      
      print('Cleaned up old data for user: $userId');
    } catch (e) {
      print('Error cleaning up old data: $e');
    }
  }
}
