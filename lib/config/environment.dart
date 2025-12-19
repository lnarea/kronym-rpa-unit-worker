import 'dart:io';
import 'package:dotenv/dotenv.dart';

class Environment {
  static late String organizationId;
  static late String supabaseUrl;
  static late String supabaseKey;
  static late int executionInterval;
  
  static Future<void> load() async {
    try {
      if (File('.env').existsSync()) {
        final env = DotEnv()..load();
        
        organizationId = env['ORGANIZATION_ID'] ?? 
                        Platform.environment['ORGANIZATION_ID'] ?? 
                        'unknown';
        
        supabaseUrl = env['SUPABASE_URL'] ?? 
                     Platform.environment['SUPABASE_URL'] ?? 
                     '';
        
        supabaseKey = env['SUPABASE_ANON_KEY'] ?? 
                     Platform.environment['SUPABASE_ANON_KEY'] ?? 
                     '';
        
        executionInterval = int.tryParse(
          env['EXECUTION_INTERVAL'] ?? 
          Platform.environment['EXECUTION_INTERVAL'] ?? 
          '15'
        ) ?? 15;
      } else {
        organizationId = Platform.environment['ORGANIZATION_ID'] ?? 'unknown';
        supabaseUrl = Platform.environment['SUPABASE_URL'] ?? '';
        supabaseKey = Platform.environment['SUPABASE_ANON_KEY'] ?? '';
        executionInterval = int.tryParse(
          Platform.environment['EXECUTION_INTERVAL'] ?? '15'
        ) ?? 15;
      }
      
      if (organizationId == 'unknown') {
        throw Exception('ORGANIZATION_ID no configurado');
      }
      
      if (supabaseUrl.isEmpty) {
        throw Exception('SUPABASE_URL no configurado');
      }
      
      if (supabaseKey.isEmpty) {
        throw Exception('SUPABASE_ANON_KEY no configurado');
      }
      
    } catch (e) {
      print('❌ Error cargando configuración: $e');
      rethrow;
    }
  }
}