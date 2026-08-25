import 'package:http/http.dart' as http;

import '../auth/auth_session_service.dart';
import '../auth/session_store.dart';

class AuthenticatedClient extends http.BaseClient {
  final http.Client _inner;

  AuthenticatedClient({http.Client? inner}) : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    _attachAccessToken(request);
    final retryRequest = _cloneRequest(request);

    final response = await _inner.send(request);
    if (response.statusCode != 401 || retryRequest == null) {
      return response;
    }

    await response.stream.drain<void>();
    await AuthSessionService.refreshSession();

    _attachAccessToken(retryRequest);
    return _inner.send(retryRequest);
  }

  void _attachAccessToken(http.BaseRequest request) {
    final token = SessionStore.accessToken;
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    } else {
      request.headers.remove('Authorization');
    }
  }

  http.BaseRequest? _cloneRequest(http.BaseRequest request) {
    if (request is! http.Request) return null;

    final clone = http.Request(request.method, request.url)
      ..headers.addAll(request.headers)
      ..bodyBytes = request.bodyBytes
      ..encoding = request.encoding
      ..followRedirects = request.followRedirects
      ..maxRedirects = request.maxRedirects
      ..persistentConnection = request.persistentConnection;
    return clone;
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
