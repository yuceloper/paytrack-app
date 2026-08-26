import 'dart:convert';

import '../config/app_config.dart';
import '../network/authenticated_client.dart';

class AccountProfile {
  final int userId;
  final String name;
  final String email;
  final String provider;
  final bool guest;

  const AccountProfile({
    required this.userId,
    required this.name,
    required this.email,
    required this.provider,
    required this.guest,
  });

  factory AccountProfile.fromJson(Map<String, dynamic> json) {
    return AccountProfile(
      userId: (json['userId'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      provider: json['provider']?.toString() ?? 'GUEST',
      guest: json['guest'] == true,
    );
  }
}

class AccountProfileService {
  AccountProfileService._();

  static Future<AccountProfile> load() async {
    final client = AuthenticatedClient();
    try {
      final response = await client.get(
        Uri.parse('${AppConfig.apiBaseUrl}/api/v1/auth/me'),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AccountProfileException('Hesap bilgileri alınamadı (${response.statusCode}).');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['data'] is! Map<String, dynamic>) {
        throw const AccountProfileException('Hesap yanıtı beklenen formatta değil.');
      }
      return AccountProfile.fromJson(decoded['data'] as Map<String, dynamic>);
    } finally {
      client.close();
    }
  }
}

class AccountProfileException implements Exception {
  final String message;

  const AccountProfileException(this.message);

  @override
  String toString() => message;
}
