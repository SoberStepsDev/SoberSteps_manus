# SoberSteps — Launch Checklist

> Ostatnia aktualizacja: 2026-04-06 (Sesja 21 — Recovery+ Audit)

---

## Supabase ✅

- [x] Wszystkie tabele z RLS (74+ polityk)

- [x] RPC: `get_days_sober`, `check_checkin_rate_limit`, `check_post_rate_limit`, `check_three_am_rate_limit`, `check_letter_rate_limit`, `flag_post`, `get_ab_variant(p_user_id)`

- [x] Edge Functions: `moderate_three_am_post`, `notify_users`, `naomi-feedback`, `send_welcome_email`, `send_moderation_email_brevo`, `crash-log-feedback`, `send_confirmation_email`

- [x] Anonymous auth — **⚠️ WŁĄCZYĆ RĘCZNIE**: Dashboard → Auth → Providers → Anonymous → Enable

- [x] Trigger `moderate_three_am_post` na tabeli `three_am_wall` (E2E verified)

---

## RevenueCat ✅

- [x] Projekt `proj92c2b22c` — SoberSteps

- [x] Entitlement `pro` (lookup_key: `pro`) z 4 produktami Play Store

- [x] Pakiety: monthly/annual/lifetime/family

- [x] **⚠️ RĘCZNIE**: Dashboard → Apps → SoberSteps (Play Store) → Package Name: `com.sobersteps.app`

- [ ] **⚠️ RĘCZNIE**: Skonfigurować App Store Connect (iOS) jeśli dotyczy

- [ ] Test sandbox: zakup → `entitlements['pro'].isActive == true`

---

## Recovery+ Feature Gating ✅

- [x] `ProGateWidget` — blur overlay + CTA → `/paywall`

- [x] `PurchaseProvider` — CustomerInfo listener (`onCustomerInfoUpdated`), AB variant z Supabase (`get_ab_variant`)

- [x] Feature gates zaimplementowane: naomi, craving_surf soundscapes, return_to_self (PRO paths), future_letters (limit 1 free), krytyk_patterns, milestones celebration, trigger_tracker, accountability, crash_log (save reflection), streak_protection_service, tts_service (milestone voice)

- [ ] Feature gate audit: karma_mirror, savings_health, goals, mirror_moment, experiment, x_marker, krytyk_log → **patrz `CURSOR_PROMPT_RECOVERY_PLUS.md`**

- [ ] `PremiumWelcomeScreen` — weryfikacja benefitów + nawigacja → `/home`

- [ ] Test E2E: free user → PRO gate visible → paywall → zakup → gate znika

---

## OneSignal

- [ ] Stworzyć aplikację w OneSignal Dashboard

- [ ] Skopiować App ID do `AppConstants.oneSignalAppId`

- [ ] Skonfigurować Firebase Cloud Messaging (FCM) w OneSignal

- [ ] Test: push na urządzeniu testowym

---

## Firebase

- [ ] Pobrać `google-services.json` (Android) i `GoogleService-Info.plist` (iOS)

- [ ] Umieścić `google-services.json` w `android/app/`

- [ ] Włączyć Crashlytics w Firebase Console

- [ ] Test: `FirebaseCrashlytics.instance.crash()` → widoczny w dashboard

---

## Android Build

- [x] `applicationId = "com.sobersteps.app"`

- [x] `minSdk = 21`

- [x] `targetSdk = 34`

- [x] `isMinifyEnabled = true`, `isShrinkResources = true`

- [x] Keystore signing config (z `key.properties`)

- [ ] Stworzyć keystore: `keytool -genkey -v -keystore release.jks -alias sobersteps -keyalg RSA -keysize 2048 -validity 10000`

- [ ] Uzupełnić `android/key.properties`

- [ ] `flutter build appbundle --release --dart-define=IS_DEVELOPMENT=false ...`

---

## Secrets (GitHub Actions)

Dodać w: Settings → Secrets → Actions:

- [ ] `KEYSTORE_BASE64` — `base64 release.jks`

- [ ] `KEYSTORE_PASSWORD`

- [ ] `KEY_PASSWORD`

- [ ] `KEY_ALIAS`

- [ ] `SUPABASE_ANON_KEY`

- [ ] `REVENUECAT_ANDROID_KEY`

- [ ] `ONESIGNAL_APP_ID`

---

## Assets

- [x] `assets/images/SoberStepsLogo.png`

- [x] `assets/audio/milestones/` — 11 plików MP3

- [x] `assets/audio/craving/` — 3 pliki MP3

- [ ] `assets/voice/` — Naomi voice files (ElevenLabs, voice ID: `2Hw5QTX3wstf1sLYfhhk`) — **BRAKUJE**

- [ ] `assets/audio/three_am/` — sprawdzić zawartość

- [ ] Lottie animations — sprawdzić czy CDN URL działa lub dodać lokalnie

---

## Przed publikacją na Google Play

- [ ] Privacy Policy URL: `AppConstants.privacyUrl`

- [ ] Terms of Service URL: `AppConstants.termsUrl`

- [x] SAMHSA banner widoczny na ProfileScreen (non-dismissible)

- [x] Medical Disclaimer w kroku 1 onboardingu

- [x] Age Gate (18+) w kroku 1 onboardingu

- [ ] Data Safety form w Google Play Console

- [ ] Screenshots (min. 2 telefon, 1 tablet)

- [ ] Feature graphic (1024×500)

- [ ] App icon (512×512)

---

## Flutter Analyze

```bash
flutter analyze --no-fatal-infos
# Expected: 0 errors
```

## Release Build Command

```bash
flutter build appbundle --release \
  --dart-define=IS_DEVELOPMENT=false \
  --dart-define=SUPABASE_ANON_KEY=<key> \
  --dart-define=REVENUECAT_ANDROID_KEY=<key> \
  --dart-define=ONESIGNAL_APP_ID=<id>
```

---

## Status Fazy 2

| Sesja | Moduł | Status |
| --- | --- | --- |
| S1 | Fundament Flutter | ✅ |
| S2-3 | Onboarding + Auth | ✅ (Cursor AI) |
| S4 | HomeScreen + SobrietyProvider | ✅ |
| S5 | Check-in + JournalProvider | ✅ |
| S6 | Milestones + Celebrations | ✅ |
| S7 | Paywall + RevenueCat | ✅ |
| S8 | 3AM Wall + Edge Function | ✅ |
| S9 | Craving Surf + Soundscapes | ✅ |
| S10 | Future Letters | ✅ |
| S11 | Community Wall | ✅ |
| S12 | NotificationService | ✅ |
| S13 | AnalyticsService | ✅ |
| S14 | Self-Compassion Hub | ✅ |
| S15 | Return to Self | ✅ |
| S16 | Naomi AI | ✅ |
| S17 | ProfileScreen | ✅ |
| S18 | MirrorMind Data Foundation | ✅ |
| S19 | Security + Offline Sync | ✅ |
| S20 | Launch Prep | ✅ |
| S21 | Recovery+ Audit & Completion | ⏳ (patrz `CURSOR_PROMPT_RECOVERY_PLUS.md`) |
