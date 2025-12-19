import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class InstanceInfo {
  final String instanceId;
  final String publicIp;
  final String privateIp;
  final String availabilityZone;
  final String region;
  final String instanceType;
  final Map<String, String> tags;
  
  InstanceInfo({
    required this.instanceId,
    required this.publicIp,
    required this.privateIp,
    required this.availabilityZone,
    required this.region,
    required this.instanceType,
    required this.tags,
  });
  
  static Future<InstanceInfo> gather() async {
    try {
      // AWS/Lightsail metadata endpoint
      const metadataUrl = 'http://169.254.169.254/latest';
      
      // Obtener información básica
      final instanceId = await _getMetadata('$metadataUrl/meta-data/instance-id');
      final publicIp = await _getMetadata('$metadataUrl/meta-data/public-ipv4');
      final privateIp = await _getMetadata('$metadataUrl/meta-data/local-ipv4');
      final availabilityZone = await _getMetadata('$metadataUrl/meta-data/placement/availability-zone');
      final instanceType = await _getMetadata('$metadataUrl/meta-data/instance-type');
      
      // Extraer región de la zona
      final region = availabilityZone.substring(0, availabilityZone.length - 1);
      
      // Obtener tags (si están disponibles)
      Map<String, String> tags = {};
      try {
        // Lightsail no expone tags en metadata, pero podemos intentar
        // Por ahora, dejamos vacío o agregamos tags básicos
        tags = {
          'instance_id': instanceId,
          'public_ip': publicIp,
        };
      } catch (e) {
        // Tags no disponibles, continuar
      }
      
      return InstanceInfo(
        instanceId: instanceId,
        publicIp: publicIp,
        privateIp: privateIp,
        availabilityZone: availabilityZone,
        region: region,
        instanceType: instanceType,
        tags: tags,
      );
      
    } catch (e) {
      print('⚠️  No se pudo obtener metadata de AWS');
      print('   Usando valores por defecto (modo desarrollo)');
      
      // Valores por defecto para desarrollo local
      return InstanceInfo(
        instanceId: 'local-dev',
        publicIp: 'localhost',
        privateIp: '127.0.0.1',
        availabilityZone: 'local-zone',
        region: 'local',
        instanceType: 'dev',
        tags: {'mode': 'development'},
      );
    }
  }
  
  static Future<String> _getMetadata(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'text/plain'},
      ).timeout(Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        return response.body.trim();
      }
      throw Exception('Status ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching metadata from $url: $e');
    }
  }
  
  Map<String, dynamic> toJson() {
    return {
      'instance_id': instanceId,
      'public_ip': publicIp,
      'private_ip': privateIp,
      'availability_zone': availabilityZone,
      'region': region,
      'instance_type': instanceType,
      'tags': tags,
    };
  }
}