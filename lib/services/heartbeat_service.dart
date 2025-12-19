// lib/services/heartbeat_service.dart - ACTUALIZADO CON SCRAPING

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kronym_rpa_unit_worker/config/environment.dart';
import 'package:kronym_rpa_unit_worker/services/instance_info.dart';
import 'package:kronym_rpa_unit_worker/services/scraper_service.dart';

class HeartbeatService {
  final String organizationId;
  final InstanceInfo instanceInfo;
  final ScraperService scraper;  // ⭐ Agregado
  
  HeartbeatService({
    required this.organizationId,
    required this.instanceInfo,
    required this.scraper,  // ⭐ Agregado
  });
  
  Future<void> sendHeartbeat() async {
    final startTime = DateTime.now();
    
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('💓 HEARTBEAT - ${startTime.toIso8601String()}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    try {
      // 1. Realizar scraping de Google
      Map<String, dynamic>? scrapingData;
      try {
        scrapingData = await scraper.scrapeGoogle();
      } catch (e) {
        print('   ⚠️  Error en scraping: $e');
        scrapingData = {
          'success': false,
          'error': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
      
      // 2. Actualizar heartbeat en Supabase
      await _updateDatabaseHeartbeat();
      
      // 3. Enviar email con datos de scraping
      await _sendEmailNotification(startTime, scrapingData);
      
      final duration = DateTime.now().difference(startTime);
      print('✅ Heartbeat completado en ${duration.inSeconds}s');
      print('⏰ Próximo heartbeat en ${Environment.executionInterval} minutos');
      print('');
      
    } catch (e) {
      print('❌ Error en heartbeat: $e');
      print('');
    }
  }
  
  Future<void> _updateDatabaseHeartbeat() async {
    try {
      print('📊 Actualizando heartbeat en base de datos...');
      
      final url = Uri.parse(
        '${Environment.supabaseUrl}/rest/v1/instance_lifecycle'
        '?instance_id=eq.${instanceInfo.instanceId}'
      );
      
      final response = await http.patch(
        url,
        headers: {
          'apikey': Environment.supabaseKey,
          'Authorization': 'Bearer ${Environment.supabaseKey}',
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: jsonEncode({
          'last_heartbeat': DateTime.now().toIso8601String(),
        }),
      );
      
      if (response.statusCode == 204 || response.statusCode == 200) {
        print('   ✓ Base de datos actualizada');
      } else {
        print('   ⚠️  Status ${response.statusCode}: ${response.body}');
      }
      
    } catch (e) {
      print('   ❌ Error actualizando BD: $e');
    }
  }
  
  Future<void> _sendEmailNotification(
    DateTime timestamp, 
    Map<String, dynamic>? scrapingData,  // ⭐ Agregado
  ) async {
    try {
      print('📧 Enviando notificación por email...');
      
      final url = Uri.parse(
        '${Environment.supabaseUrl}/functions/v1/send-heartbeat-notification'
      );
      
      final payload = {
        'organization_id': organizationId,
        'timestamp': timestamp.toIso8601String(),
        'instance_info': instanceInfo.toJson(),
        'status': 'running',
        'message': 'Worker ejecutándose correctamente',
        'scraping_data': scrapingData,  // ⭐ Agregado
      };
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${Environment.supabaseKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('   ✓ Email enviado: ${data['email_id'] ?? 'OK'}');
      } else {
        print('   ⚠️  Status ${response.statusCode}: ${response.body}');
      }
      
    } catch (e) {
      print('   ❌ Error enviando email: $e');
    }
  }
}