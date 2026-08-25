import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'session_store.dart';

class AuthSessionService {
  AuthSessionService._();

  static const _storage = FlutterSecureStorage();
  static const _userIdKey = 'auth.userId';
  static const _accessTokenKey = 'auth.accessToken';
  static const _refreshTokenKey = 'auth.refreshToken';
  static const _guestKey = 'auth.guest';
  static const _bootstrapTimeout = Duration(seconds: 8);

  static Future<void> initialize() async {
    final userId = int.tryParse(await _storage.read(key: _userIdKey) ?? '');
    final accessToken = await _storage.read(key: _accessTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    final guest = (await _storage.read(key: _guestKey)) != 'false';

    if (userId != null && accessToken != null && refreshToken != null) {
      SessionStore.setSession(
        newUserId: userId,
        newAccessToken: accessToken,
        newRefreshToken: refreshToken,
        isGuest: guest,
      );
      return;
    }

    await _createGuestSession().timeout(
      _bootstrapTimeout,
      onTimeout: () => throw TimeoutException(
        'PayTrack sunucusuna ${_bootstrapTimeout.inSeconds} saniye içinde ulaşılamadı.',
      ),
    );
  }

  static Future<void> _createGuestSession() async {
    final response = await http.post(Uri.parse('${AppConfig.apiBaseUrl}/api/v1/auth/guest'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Guest oturumu oluşturulamadı (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    final userId = (data['userId'] as num).toInt();
    final accessToken = data['accessToken'] as String;
    final refreshToken = data['refreshToken'] as String;
    final guest = data['guest'] as bool? ?? true;

    SessionStore.setSession(
      newUserId: userId,
      newAccessToken: accessToken,
      newRefreshToken: refreshToken,
      isGuest: guest,
    );

    await Future.wait([
      _storage.write(key: _userIdKey, value: userId.toString()),
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
      _storage.write(key: _guestKey, value: guest.toString()),
    ]);
  }
}
