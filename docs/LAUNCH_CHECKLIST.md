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

- [x] Feature gate audit: `savings_health`, `goals`, `mirror_moment`, `experiment`, `x_marker`, `krytyk_log` — `ProGateWidget`; **karma_mirror** — dodany `karma_mirror_gate` (2026-04)

- [x] `PremiumWelcomeScreen` — `isPro`, nawigacja → `/home`; analytics `premium_welcome_viewed`

- [x] Lejek free→PRO: `pro_gate_cta` + poprawne `arguments` trasy `/paywall` (`trigger`); po zakupie → `/premium-welcome`; job CI `integration-test-android`

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

## Weryfikacja na urządzeniu (krótki protokół)

1. **Build debug + instalacja:** `flutter build apk --debug` → `adb install -r build/app/outputs/flutter-apk/app-debug.apk` (telefon z USB debugging).
2. **RevenueCat (sandbox Google Play):** konto testowe / licencjobiorca w Play Console → `/paywall` → zakup testowy → w aplikacji odblokowany PRO (`PurchaseProvider.isPro` / badge Recovery+ na profilu). Po sukcesie zaznacz powyżej „Test sandbox”.
3. **OneSignal:** po FCM + `google-services.json` → uruchom apkę → **Profil → powiadomienia** lub onboarding (żądanie zgody) → w OneSignal: *Audience → Subscriptions* / „Check Subscribed Users”. Opcjonalnie wyślij testowy push z dashboardu.
4. **Crashlytics:** w Firebase Console włącz Crashlytics dla projektu → na **debug APK**: *Profil* → sekcja **Debug** → „Crashlytics test crash” (tylko `kDebugMode`) → po kilku minutach widać crash w konsoli. **Nie** używaj tego przycisku na buildzie release sklepowym.

---

## Android Build

- [x] `applicationId = "com.sobersteps.app"`

- [x] `minSdk = 21`

- [x] `targetSdk = 34`

- [x] `isMinifyEnabled = true`, `isShrinkResources = true`

- [x] Keystore signing config (z `key.properties`)

- [ ] Stworzyć keystore: `keytool -genkey -v -keystore release.jks -alias sobersteps -keyalg RSA -keysize 2048 -validity 10000`

- [ ] Uzupełnić `android/key.properties`

- [ ] **Upload key SHA-1 (SoberSteps, Play Console):** `5C:58:19:49:85:21:D2:34:E6:40:C5:7F:F0:FA:D4:FC:FC:0F:C5:E5` — `keytool -list -v` na używanym `.jks` musi pokazać ten sam odcisk; inaczej upload AAB się nie powiedzie.

- [ ] `flutter build appbundle --release --dart-define=IS_DEVELOPMENT=false ...`

---

## Google Play — przekazanie do review

**Artefakt:** po udanym buildzie: `build/app/outputs/bundle/release/app-release.aab`

**Komenda (release, produkcyjne flagi):**

```bash
flutter build appbundle --release --dart-define=IS_DEVELOPMENT=false
```

**Podpis:** bez pliku `android/key.properties` Gradle używa **klucza debug** — taki AAB **nie nadaje się** do produkcji w Play (upload się nie powiedzie lub trafi tylko do ograniczonych ścieżek testowych). Przed review: keystore + `key.properties` (wzór: `android/key.properties.example`), potem **przebuduj** AAB.

**Błąd uploadu: „signed with the wrong key” (SHA1 się nie zgadza)**  
- Komunikat z Play podaje **oczekiwany** certyfikat (**upload key** zarejestrowany przy aplikacji).  
- Odcisk **`E4:EC:AC:E8:FC:09:A8:B3:83:B6:53:0B:C0:24:0D:AD:C1:97:C7:96`** to typowy **`~/.android/debug.keystore`** na macOS — czyli zbudowałeś release **bez** `key.properties` albo ze złym plikiem `.jks`.  
- **Naprawa:** użyj keystore’a, którego **SHA1** = ten **oczekiwany** w konsoli (np. `5C:58:19:49:…`). Ustaw `android/key.properties` (`storeFile`, `storePassword`, `keyPassword`, `keyAlias`), potem od nowa:

  `flutter clean && flutter build appbundle --release --dart-define=IS_DEVELOPMENT=false`

- **Sprawdź odcisk przed uploadem** (podstaw ścieżkę do `.jks` i alias):

  ```bash
  /Applications/Android\ Studio.app/Contents/jbr/Contents/Home/bin/keytool -list -v -keystore /ścieżka/do/upload-keystore.jks -alias TWÓJ_ALIAS
  ```

  Porównaj linię **SHA1** z Play Console → **App integrity** (lub tekstem błędu przy uploadzie).

- **Jeśli nie masz już pliku `.jks`** o tym odcisku: w Play Console → **App integrity** / ochrona integralności → **Request upload key reset** (lub kreator **Change signing key**) — bez tego żaden lokalny build nie przejdzie walidacji uploadu.

**W konsoli (skrót):**

1. **Testowanie i wydanie** → wybór ścieżki (**Wewnętrzne** / **Zamknięte** / **Otwarte** / **Produkcja**) → **Utwórz nowe wydanie** → wgraj `.aab`.
2. Uzupełnij **informacje o wydaniu** (notatki dla recenzenta / co nowego).
3. **Zapisz** → przejdź przez **Podsumowanie wydania** (polityka prywatności, **Bezpieczeństwo danych**, deklaracje reklam / aplikacji informacyjnej, wiek docelowy, kraje).
4. **Wyślij do sprawdzenia** (lub najpierw **Wewnętrzne testy**, żeby zweryfikować instalację z Play).

**Wersja:** `pubspec.yaml` → `version: x.y.z+NN` — **NN** (`versionCode`) musi rosnąć przy każdym nowym uploadzie tego samego pakietu.

**Bezpośrednie linki (SoberSteps, konto ReturnToYourself)** — zastąp `u/0` innym indeksem konta Google, jeśli używasz wielu:

| Sekcja | URL |
|--------|-----|
| Panel | `https://play.google.com/console/u/0/developers/5406187422596596688/app/4973377659246608619/app-dashboard` |
| Lista sklepu (en-US) | `https://play.google.com/console/u/0/developers/5406187422596596688/app/4973377659246608619/main-store-listing` |
| Treść aplikacji (deklaracje) | `https://play.google.com/console/u/0/developers/5406187422596596688/app/4973377659246608619/app-content/overview` |
| Testy wewnętrzne | `https://play.google.com/console/u/0/developers/5406187422596596688/app/4973377659246608619/tracks/internal-testing` |
| Testy zamknięte | `https://play.google.com/console/u/0/developers/5406187422596596688/app/4973377659246608619/tracks/closed-testing` |

**Stan sprawdzony w konsoli (2026-04):** opis sklepu i grafiki wypełnione; *App content* → „You're all caught up”. Brak wydania na ścieżce **Internal testing** — następny krok: **Select testers** + **Create new release** + upload podpisanego `.aab`.

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
