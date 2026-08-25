import 'package:http/http.dart' as http;

import '../auth/session_store.dart';

class AuthenticatedClient extends http.BaseClient {
  final http.Client _inner;

  AuthenticatedClient({http.Client? inner}) : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final token = SessionStore.accessToken;
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
