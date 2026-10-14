# PayTrack iOS App Store Release

## Production configuration

Production API:

```text
https://paytrack-api.comlekteevyemekleri.com
```

`AppConfig.apiBaseUrl` uses this URL by default. `API_BASE_URL` may still be overridden with `--dart-define` for development or staging builds.

Google account linking requires both compile-time values:

- `GOOGLE_IOS_CLIENT_ID`
- `GOOGLE_SERVER_CLIENT_ID`

## Release build

Use Xcode 26 or later and the iOS 26 SDK or later for App Store Connect uploads.

```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..

flutter build ipa --release \
  --dart-define=API_BASE_URL=https://paytrack-api.comlekteevyemekleri.com \
  --dart-define=GOOGLE_IOS_CLIENT_ID=<IOS_CLIENT_ID> \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<WEB_CLIENT_ID>
```

If Google account linking is intentionally disabled for a build, remove or hide the related UI rather than shipping it with empty client IDs.

## App Store checklist

- Version/build number is unique in App Store Connect.
- Bundle identifier is `com.yuceloper.paytrack`.
- Signing team and distribution certificate/provisioning are valid in Xcode.
- Production API responds over valid HTTPS.
- Google OAuth iOS client matches bundle identifier and URL scheme.
- Google server/web client ID matches the backend `GOOGLE_CLIENT_ID`.
- App icon includes the 1024x1024 App Store icon and required device sizes.
- Test Face ID/local authentication on a physical device.
- Test local notifications and permission flow on a physical device.
- Generate and review Xcode Privacy Report for bundled third-party SDKs.
- Complete App Privacy answers in App Store Connect based on actual data collection.
- Provide a public Privacy Policy URL in App Store Connect.
- Complete the current age-rating questionnaire.
- Upload to TestFlight and run a production smoke test before submitting for review.

## Smoke test

Verify at minimum:

1. Fresh install creates/obtains a guest session.
2. Main data screens load from the production API.
3. Create/edit/delete flows persist after relaunch.
4. Google account linking succeeds and the linked session remains valid.
5. Face ID protected areas behave correctly after app relaunch.
6. Local reminders/notifications fire at the expected time.
7. App works with Wi-Fi and cellular data.
8. No request targets a LAN address or plain HTTP endpoint.
