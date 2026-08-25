class SessionStore {
  SessionStore._();

  static int? userId;
  static String? accessToken;
  static String? refreshToken;
  static bool guest = true;

  static bool get hasSession => userId != null && accessToken != null;

  static void setSession({
    required int newUserId,
    required String newAccessToken,
    required String newRefreshToken,
    required bool isGuest,
  }) {
    userId = newUserId;
    accessToken = newAccessToken;
    refreshToken = newRefreshToken;
    guest = isGuest;
  }

  static void clear() {
    userId = null;
    accessToken = null;
    refreshToken = null;
    guest = true;
  }
}
