import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';

import '../config/app_config.dart';
import '../network/authenticated_client.dart';
import 'auth_session_service.dart';
import 'session_store.dart';

class GoogleLinkService {
  GoogleLinkService._();

  static const String _iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
  static const String _serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
  static bool _initialized = false;

  static bool get isConfigured => _iosClientId.isNotEmpty && _serverClientId.isNotEmpty;

  static Future<void> linkCurrentGuest() async {
    if (!SessionStore.guest) return;
    if (!isConfigured) {
      throw const GoogleLinkException(
        'Google girişi henüz yapılandırılmadı. GOOGLE_IOS_CLIENT_ID ve GOOGLE_SERVER_CLIENT_ID gerekli.',
      );
    }

    final signIn = GoogleSignIn.instance;
    if (!_initialized) {
      await signIn.initialize(
        clientId: _iosClientId,
        serverClientId: _serverClientId,
      );
      _initialized = true;
    }

    if (!signIn.supportsAuthenticate()) {
      throw const GoogleLinkException('Bu platform Google hesap bağlamayı desteklemiyor.');
    }

    final account = await signIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const GoogleLinkException('Google kimlik tokenı alınamadı.');
    }

    final client = AuthenticatedClient();
    try {
      final response = await client.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/v1/auth/google/link'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        String? message;
        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          final error = body['error'];
          if (error is Map<String, dynamic>) {
            message = error['message']?.toString();
          }
        } catch (_) {}
        throw GoogleLinkException(message ?? 'Google hesabı bağlanamadı (${response.statusCode}).');
      }

      await AuthSessionService.applySessionResponse(response.body);
    } finally {
      client.close();
    }
  }
}

class GoogleLinkException implements Exception {
  final String message;

  const GoogleLinkException(this.message);

  @override
  String toString() => message;
}
