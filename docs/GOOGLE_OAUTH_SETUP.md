# Google OAuth setup (iOS)

PayTrack uses two Google OAuth client IDs:

- `GOOGLE_IOS_CLIENT_ID`: OAuth client of type **iOS** for the Flutter app.
- `GOOGLE_SERVER_CLIENT_ID`: OAuth client of type **Web application**. This is used as the server client ID / token audience when the backend verifies Google ID tokens.

## 1. Create Google Cloud project

1. Open Google Cloud Console.
2. Create/select the PayTrack project.
3. Configure **Google Auth Platform / OAuth consent screen**.
4. For development, add your Google account as a test user if the app is still in Testing mode.

## 2. Create the iOS OAuth client

Create **Credentials → OAuth client ID → iOS** and use the Bundle Identifier from the PayTrack iOS target.

The current Bundle Identifier should be read from `ios/Runner.xcodeproj/project.pbxproj` before creating the client; do not guess it.

Copy the resulting client ID, for example:

```text
1234567890-abcdef.apps.googleusercontent.com
```

Pass it to Flutter as `GOOGLE_IOS_CLIENT_ID`.

### URL scheme

Google Sign-In on iOS needs the reversed iOS client ID as a URL scheme.

If the client ID is:

```text
1234567890-abcdef.apps.googleusercontent.com
```

then add this URL scheme to `ios/Runner/Info.plist`:

```text
com.googleusercontent.apps.1234567890-abcdef
```

Do not commit a fake/replaced value. Add the real value once the client is created.

## 3. Create the server OAuth client

Create another OAuth client of type **Web application**.

Copy that client ID and pass it to Flutter as `GOOGLE_SERVER_CLIENT_ID`.

The backend must verify Google ID tokens using this same Web client ID as the expected audience.

## 4. Run locally

```bash
flutter run \
  --dart-define=GOOGLE_IOS_CLIENT_ID=<ios-client-id>.apps.googleusercontent.com \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
```

Do not commit OAuth secrets. OAuth client IDs are identifiers rather than secrets, but using `--dart-define` keeps environment-specific configuration out of source control.

## 5. Expected account-link flow

1. PayTrack starts with the existing guest session.
2. User taps **Google ile hesabını bağla**.
3. iOS Google Sign-In returns a Google ID token.
4. PayTrack sends that ID token to the backend while the guest Bearer token is still active.
5. Backend validates the Google token.
6. Backend upgrades/links the same PayTrack user instead of creating an unrelated user, preserving existing payments, incomes, accounts and transactions.
7. Backend returns a fresh PayTrack session and Flutter replaces the guest tokens in secure storage.

For an already-linked Google identity, the backend should use an explicit conflict/recovery policy rather than silently merging financial data from two unrelated PayTrack user IDs.
