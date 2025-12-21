import 'dart:async';
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

  static const _base = 'http://169.254.169.254/latest';
  static String? _tokenCache;

  /// Punto de entrada principal
  static Future<InstanceInfo> gather() async {
    try {
      final token = await _getToken();

      final instanceId =
          await _getMetadata('meta-data/instance-id', token);
      final publicIp =
          await _getMetadata('meta-data/public-ipv4', token);
      final privateIp =
          await _getMetadata('meta-data/local-ipv4', token);
      final availabilityZone =
          await _getMetadata('meta-data/placement/availability-zone', token);
      final instanceType =
          await _getMetadata('meta-data/instance-type', token);

      final region =
          availabilityZone.substring(0, availabilityZone.length - 1);

      return InstanceInfo(
        instanceId: instanceId,
        publicIp: publicIp,
        privateIp: privateIp,
        availabilityZone: availabilityZone,
        region: region,
        instanceType: instanceType,
        tags: {
          'provider': 'aws-lightsail',
          'instance_id': instanceId,
        },
      );
    } catch (e, st) {
      print('⚠️  AWS metadata no disponible, usando modo desarrollo');
      print(e);
      print(st);

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

  /// === IMDSv2 TOKEN ===
  static Future<String> _getToken() async {
    if (_tokenCache != null) return _tokenCache!;

    final response = await http
        .put(
          Uri.parse('$_base/api/token'),
          headers: {
            'X-aws-ec2-metadata-token-ttl-seconds': '21600',
          },
        )
        .timeout(const Duration(seconds: 3));

    if (response.statusCode != 200) {
      throw Exception('IMDSv2 token failed: ${response.statusCode}');
    }

    _tokenCache = response.body;
    return _tokenCache!;
  }

  /// === GET METADATA ===
  static Future<String> _getMetadata(
    String path,
    String token,
  ) async {
    final response = await http
        .get(
          Uri.parse('$_base/$path'),
          headers: {
            'X-aws-ec2-metadata-token': token,
          },
        )
        .timeout(const Duration(seconds: 3));

    if (response.statusCode == 200) {
      return response.body.trim();
    }

    throw Exception(
      'Metadata $path failed: ${response.statusCode}',
    );
  }

  Map<String, dynamic> toJson() => {
        'instance_id': instanceId,
        'public_ip': publicIp,
        'private_ip': privateIp,
        'availability_zone': availabilityZone,
        'region': region,
        'instance_type': instanceType,
        'tags': tags,
      };
}