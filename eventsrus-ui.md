# EventsRUs Mobile App
**Project:** `eventsrus-ui` | **Stack:** Flutter (Dart), Android only | **Repo:** `github.com/ianorozcoai/eventsrus-ui`
**Parent doc:** `claude.md` (project root). Backend contract: `../eventsrus-backend/eventsrus-backend.md`.

## Role
Native client for planners and suppliers, with feature parity with the website. Talks to `eventsrus-backend` over REST (Dio).

## Specs
- State: `provider`. Secure token storage: `flutter_secure_storage`. Features live in `lib/features/<feature>/{data,presentation,state}`; two navigation shells (planner, vendor) chosen by `AuthController.role`.
- Android id: `com.eventsrus.eventsrus_ui` (matches Firebase project `eventsrus-507816`). Version `1.0.0+1`.
- Sign-in and integrations: `google_sign_in`, `flutter_web_auth_2` (Calendar connect), `firebase_messaging` and `flutter_local_notifications` (push).
- Release signing: `android/key.properties` + `eventsrus-upload-key.jks` (both git-ignored; never commit).
- Backend address: `AppConfig` defaults to the emulator (`10.0.2.2:8080`). Release builds must pass `--dart-define=BACKEND_BASE_URL=...` (and `WEB_BASE_URL`).
- CI exists (Analyze and tests, pinned Flutter version).

## Payments in the app (Google Play risk)
The paywall (`features/subscription/`) offers PayPal (external browser) and GCash (manual). There is no Play Billing yet. Decision (2026-10-16): the Android app will use Play Billing only, and PayPal/GCash stay on the website. See "Payments decision" in `docs/play-audit.md`.
