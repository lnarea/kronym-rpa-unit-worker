// lib/services/scraper_service.dart

import 'package:puppeteer/puppeteer.dart';
import 'dart:io';

class ScraperService {
  Browser? _browser;
  
  /// Inicializar el navegador
  Future<void> init() async {
    try {
      print('🌐 Iniciando navegador...');
      
      // Configuración del navegador según el sistema operativo
      if (Platform.isWindows) {
        // En Windows: usar Chrome instalado o descargar Chromium
        _browser = await puppeteer.launch(
          headless: true,
          args: [
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-dev-shm-usage',
            '--disable-gpu',
          ],
        );
      } else {
        // En Linux: dejar que Puppeteer use su propio Chromium
        // Sin executablePath - Puppeteer descargará Chromium automáticamente
        _browser = await puppeteer.launch(
          headless: true,
          args: [
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-dev-shm-usage',
            '--disable-gpu',
          ],
        );
      }
      
      print('   ✓ Navegador iniciado');
    } catch (e) {
      print('   ❌ Error iniciando navegador: $e');
      rethrow;
    }
  }
  
  /// Navegar a Google y extraer el título
  Future<Map<String, dynamic>> scrapeGoogle() async {
    if (_browser == null) {
      throw Exception('Navegador no inicializado. Llama a init() primero.');
    }
    
    Page? page;
    
    try {
      print('🔍 Navegando a Google...');
      
      page = await _browser!.newPage();
      
      // Configurar viewport
      await page.setViewport(DeviceViewport(width: 1920, height: 1080));
      
      // Navegar a Google - usar domContentLoaded para compatibilidad
      await page.goto('https://www.google.com', wait: Until.domContentLoaded);
      
      // Esperar un poco más para asegurar carga completa
      await Future.delayed(Duration(seconds: 2));
      
      // Extraer el título de la página
      final title = await page.title;
      
      // Extraer la URL actual
      final url = page.url;
      
      print('   ✓ Título extraído: $title');
      
      return {
        'success': true,
        'title': title,
        'url': url,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      print('   ❌ Error en scraping: $e');
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } finally {
      await page?.close();
    }
  }
  
  /// Ejemplo más complejo: Buscar en Google
  Future<Map<String, dynamic>> searchGoogle(String query) async {
    if (_browser == null) {
      throw Exception('Navegador no inicializado.');
    }
    
    Page? page;
    
    try {
      print('🔍 Buscando en Google: "$query"...');
      
      page = await _browser!.newPage();
      await page.setViewport(DeviceViewport(width: 1920, height: 1080));
      
      // Navegar a Google
      await page.goto('https://www.google.com', wait: Until.domContentLoaded);
      await Future.delayed(Duration(seconds: 1));
      
      // Buscar el campo de búsqueda y escribir
      await page.type('textarea[name="q"]', query);
      await page.keyboard.press(Key.enter);
      
      // Esperar a que carguen los resultados
      await page.waitForNavigation();
      
      // Extraer el título de la página de resultados
      final title = await page.title;
      final url = page.url;
      
      // Extraer el primer resultado (opcional)
      String? firstResult;
      try {
        firstResult = await page.evaluate('''
          () => {
            const firstLink = document.querySelector('h3');
            return firstLink ? firstLink.textContent : null;
          }
        ''');
      } catch (e) {
        firstResult = null;
      }
      
      print('   ✓ Búsqueda completada');
      
      return {
        'success': true,
        'query': query,
        'title': title,
        'url': url,
        'first_result': firstResult,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      print('   ❌ Error en búsqueda: $e');
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } finally {
      await page?.close();
    }
  }
  
  /// Cerrar el navegador
  Future<void> close() async {
    try {
      await _browser?.close();
      _browser = null;
      print('   ✓ Navegador cerrado');
    } catch (e) {
      print('   ⚠️  Error cerrando navegador: $e');
    }
  }
  
  /// Verificar si el navegador está activo
  bool get isActive => _browser != null;
}