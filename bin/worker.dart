// bin/worker.dart - ACTUALIZADO CON PUPPETEER

import 'dart:async';
import 'dart:io';
import 'package:kronym_rpa_unit_worker/config/environment.dart';
import 'package:kronym_rpa_unit_worker/services/heartbeat_service.dart';
import 'package:kronym_rpa_unit_worker/services/instance_info.dart';
import 'package:kronym_rpa_unit_worker/services/scraper_service.dart';

void main() async {
  Timer? timer;
  ScraperService? scraper;
  
  try {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🚀 KRONYM RPA WORKER - CON PUPPETEER');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('');
    
    await Environment.load();
    
    final organizationId = Environment.organizationId;
    final interval = Environment.executionInterval;
    
    print('📋 Configuración:');
    print('   • Organización: $organizationId');
    print('   • Intervalo: $interval minutos');
    print('   • Supabase URL: ${Environment.supabaseUrl}');
    print('');
    
    print('📍 Obteniendo información de la instancia...');
    final instanceInfo = await InstanceInfo.gather();
    
    print('   • ID Instancia: ${instanceInfo.instanceId}');
    print('   • IP Pública: ${instanceInfo.publicIp}');
    print('   • Zona: ${instanceInfo.availabilityZone}');
    print('   • Región: ${instanceInfo.region}');
    print('');
    
    // ⭐ Inicializar el scraper
    print('🤖 Inicializando Puppeteer...');
    scraper = ScraperService();
    await scraper.init();
    print('');
    
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('✅ Worker iniciado correctamente');
    print('⏱️  Ejecutará cada $interval minutos');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('');
    
    final heartbeatService = HeartbeatService(
      organizationId: organizationId,
      instanceInfo: instanceInfo,
      scraper: scraper,  // ⭐ Pasar el scraper
    );
    
    print('📤 Enviando heartbeat inicial...');
    await heartbeatService.sendHeartbeat();
    print('');
    
    timer = Timer.periodic(Duration(minutes: interval), (t) async {
      await heartbeatService.sendHeartbeat();
    });
    
    print('🔄 Worker en ejecución...');
    print('   Presiona Ctrl+C para detener');
    print('');
    
    // Solo escuchar señales en Linux/macOS (no en Windows)
    if (!Platform.isWindows) {
      ProcessSignal.sigterm.watch().listen((signal) async {
        print('');
        print('⏹️  Señal de terminación recibida');
        timer?.cancel();
        await scraper?.close();
        exit(0);
      });
      
      ProcessSignal.sigint.watch().listen((signal) async {
        print('');
        print('⏹️  Interrupción recibida (Ctrl+C)');
        timer?.cancel();
        await scraper?.close();
        exit(0);
      });
    } else {
      // En Windows, solo manejar Ctrl+C
      ProcessSignal.sigint.watch().listen((signal) async {
        print('');
        print('⏹️  Interrupción recibida (Ctrl+C)');
        timer?.cancel();
        await scraper?.close();
        exit(0);
      });
    }
    
    // Mantener vivo indefinidamente
    await Future.delayed(Duration(days: 365 * 10));
    
  } catch (e, stackTrace) {
    print('');
    print('❌ ERROR FATAL:');
    print('   $e');
    print('');
    print('Stack trace:');
    print('$stackTrace');
    timer?.cancel();
    await scraper?.close();
    exit(1);
  }
}