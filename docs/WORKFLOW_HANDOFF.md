# SoberSteps — Faza 1 Handoff dla Cursor AI
## Status: 🔄 FAZA 2 W TOKU — Sesje 1–3 ukończone
Wygenerowano: 2026-04-04 | Ostatnia aktualizacja: 2026-04-08 (odnośniki do polityk repo)

**Polityki dokumentów (security, `pub`, keystore):** [docs/README.md](README.md) → [SECURITY.md](../SECURITY.md), [DEPENDENCIES.md](DEPENDENCIES.md), [android/KEYSTORE.md](../android/KEYSTORE.md).

---

## 1. Supabase

| Parametr | Wartość |
|---|---|
| Project ID | `kznhbcwozpjflewlzxnu` |
| URL | `https://kznhbcwozpjflewlzxnu.supabase.co` |
| Anon Key | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt6bmhiY3dvenBqZmxld2x6eG51Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIwMTU4NTcsImV4cCI6MjA4NzU5MTg1N30.CRgPK-BExwci8l6EHmJ3V9jH-ElABom62hejiBqyN_4` |
| Publishable Key | `sb_publishable_S2xzLgFSinkmRu0SZe2Hag_Wv_tlokk` |
| Region | `eu-central-1` |

### Tabele (43 tabel, RLS włączony na wszystkich, 74 polityki)

Kluczowe tabele dla Fazy 2:

| Tabela | Opis |
|---|---|
| `profiles` | Profil użytkownika, `sobriety_start_date`, `checkin_reminder_hour`, `ab_variant` |
| `journal_entries` | Check-iny: `mood (1-5)`, `craving_level (0-10)`, `triggers text[]`, `note` |
| `milestones_achieved` | Osiągnięte kamienie milowe |
| `community_posts` | Posty społeczności, kategorie: wins/hard/advice/milestones |
| `future_letters` | Listy do przyszłości, `deliver_at`, `delivered_at` |
| `three_am_wall` | Kryzys nocny, `is_visible`, `resolved_at`, `outcome_text` |
| `craving_surf_sessions` | Sesje surfowania na głodzie |
| `family_observers` | Obserwatorzy rodzinni |
| `inner_critic_log` | Dziennik krytyka (CBT Karta 1) |
| `self_experiments` | Eksperymenty behawioralne (CBT Karta 2) |
| `daily_self_acts` | X-Marker (CBT Karta 4) |
| `rts_scores` | Wyniki Return to Self |
| `mirror_entries` | Dane dla MirrorMind (zbierane w tle) |
| `return_to_self_naomi` | Wpisy Naomi AI |
| `email_leads` | Leady emailowe (INSERT bez auth) |
| `moderation_queue` | Kolejka moderacji |

### RPC Functions (wszystkie aktywne)

```dart
// Użycie w Flutter:
await supabase.rpc('get_days_sober')
await supabase.rpc('check_checkin_rate_limit')      // returns bool
await supabase.rpc('check_post_rate_limit')          // returns bool
await supabase.rpc('check_three_am_rate_limit')      // returns bool
await supabase.rpc('check_letter_rate_limit')        // returns bool (free: max 1 active)
await supabase.rpc('flag_post', params: {'post_id': id})
await supabase.rpc('get_ab_variant', params: {'p_user_id': userId})  // profiles.ab_variant → 'A'|'B'|'C'
await supabase.rpc('increment_community_post_likes', params: {'p_post_id': postId})
```

### Edge Functions (wszystkie ACTIVE)

| Funkcja | Trigger | Opis |
|---|---|---|
| `moderate_three_am_post` | INSERT na `three_am_wall` | Moderacja treści, ustawia `is_visible` |
| `notify_users` | Cron / POST | 11 typów powiadomień OneSignal |
| `naomi-feedback` | POST z Flutter | Claude AI feedback dla Naomi, rate limit 429 |
| `send_moderation_email_brevo` | Z `moderate_three_am_post` | Email do admina przy flagowaniu |
| `welcome_email` | Auth trigger | Email powitalny |
| `crash-log-feedback` | POST z Flutter | Logowanie błędów (Marginal Archive) |
| `send_confirmation_email` | Auth trigger | Email potwierdzający |

```dart
// Wywołanie Edge Function z Flutter:
final res = await supabase.functions.invoke('naomi-feedback',
  body: {'question_type': type, 'answer': text});
if (res.status == 429) throw NaomiFeedbackRateLimitException();
```

---

## 2. RevenueCat

| Parametr | Wartość |
|---|---|
| Project ID | `proj92c2b22c` |
| Play Store App ID | `appc8429cec61` |
| Public API Key (Android) | `goog_CAWCkqmXbVVmPfjzrTKDxAQMuvs` |

### ⚠️ Akcja Ręczna Wymagana

**Package name w RevenueCat Dashboard musi być zaktualizowany ręcznie:**
Dashboard → Project → Apps → SoberSteps (Play Store) → Edit → Package Name: `com.sobersteps.app`
(API nie pozwala na zmianę package_name po utworzeniu)

### Entitlement (kluczowy dla Flutter)

```dart
// ZAWSZE używaj tego klucza — case-sensitive!
final isPro = customerInfo.entitlements['pro']?.isActive ?? false;
```

| Entitlement ID | Lookup Key | Display Name | Produkty |
|---|---|---|---|
| `entlcd2ea18144` | **`pro`** | Recovery+ | monthly, annual, family, lifetime |

### Pakiety w Offering `default`

| Package | Lookup Key | Store Identifier | Typ |
|---|---|---|---|
| Monthly | `$rc_monthly` | `sobersteps_monthly_699:monthly` | subscription |
| Annual | `$rc_annual` | `sobersteps_annual_5999:annual` | subscription (default) |
| Family | `$rc_custom_family` | `sobersteps_family_999:family` | subscription |
| Lifetime | `$rc_lifetime` | `sobersteps_lifetime_8999` | one_time |

```dart
// Inicjalizacja RevenueCat w Flutter:
await Purchases.configure(
  PurchasesConfiguration('goog_CAWCkqmXbVVmPfjzrTKDxAQMuvs'),
);

// Sprawdzenie PRO:
final info = await Purchases.getCustomerInfo();
final isPro = info.entitlements['pro']?.isActive ?? false;
```

---

## 3. OneSignal

| Parametr | Akcja |
|---|---|
| App ID | Pobierz z OneSignal Dashboard → Settings → Keys & IDs |
| Konfiguracja | Zweryfikuj Android Push Certificate w Dashboard |

### Custom Tags do ustawienia przy logowaniu

```dart
// W NotificationService.setUser():
OneSignal.User.addTagWithKey('days_sober', daysSober.toString());
OneSignal.User.addTagWithKey('last_craving_level', cravingLevel.toString());
OneSignal.User.addTagWithKey('ab_variant', abVariant);
OneSignal.User.addTagWithKey('is_premium', isPro.toString());
```

### 11 typów powiadomień (server-side via `notify_users` Edge Function)

Wywołaj cron lub POST do Edge Function z `{"type": "<typ>"}`:

| Type | Trigger |
|---|---|
| `daily_checkin_reminder` | Cron: co godzinę, sprawdza `checkin_reminder_hour` |
| `near_miss_streak` | Cron: `reminder_hour + 1h`, brak check-inu |
| `pre_milestone` | Cron: dzienny, `daysSober == milestone - 1` |
| `high_craving_followup` | Cron: dzienny rano, craving >= 8 wczoraj |
| `late_night` | Cron: 22:00 UTC, brak check-inu |
| `three_day_streak` | Cron: dzienny, `daysSober == 3` |
| `milestone_achieved` | Cron: dzienny, `daysSober in MILESTONE_DAYS` |
| `reengagement` | Cron: dzienny, `last_open >= 7 dni temu` |
| `family_milestone` | Cron: przy milestone, ma family_observers |

---

## 4. Firebase Crashlytics

```dart
// main.dart — wymagana konfiguracja:
await Firebase.initializeApp();
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
runZonedGuarded(
  () => runApp(const MyApp()),
  FirebaseCrashlytics.instance.recordError,
);

// CrashService — użycie:
CrashService.setUser(userId);    // po zalogowaniu
CrashService.clearUser();        // po wylogowaniu
CrashService.recordError(e, s);  // w catch blokach
// NIGDY nie loguj: email, note, journal text, PII
```

**Wymagane pliki:**
- `android/app/google-services.json` — pobierz z Firebase Console

---

## 5. Zmienne środowiskowe (Flutter `--dart-define`)

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://kznhbcwozpjflewlzxnu.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... \
  --dart-define=REVENUE_CAT_KEY=goog_CAWCkqmXbVVmPfjzrTKDxAQMuvs \
  --dart-define=ONESIGNAL_APP_ID=<z_dashboardu> \
  --dart-define=IS_DEVELOPMENT=true
```

---

## 6. Checklist Fazy 2 (Flutter)

- [ ] `flutter create --org com.sobersteps --project-name sobersteps .`
- [ ] Skopiuj `pubspec.yaml` z `SoberSteps_manus` repo (wersje zweryfikowane)
- [ ] Ustaw `SUPABASE_URL`, `SUPABASE_ANON_KEY` w `app_constants.dart`
- [ ] Ustaw `REVENUE_CAT_KEY = 'goog_CAWCkqmXbVVmPfjzrTKDxAQMuvs'`
- [ ] Pobierz `google-services.json` z Firebase Console → `android/app/`
- [ ] **Ręcznie:** Zaktualizuj package_name w RevenueCat Dashboard na `com.sobersteps.app`
- [ ] Użyj `entitlements['pro']?.isActive` (lowercase!) wszędzie
- [ ] Zaimplementuj `DailyPerspectiveWidget` na HomeScreen (brakuje w obecnym repo)
- [ ] Zaimplementuj `SelfCompassionScreen` + 5 kart CBT (brakuje w obecnym repo)
- [ ] Zaimplementuj `MirrorMindService` z auto-capture hooks

---

## 7. Stan Fazy 2 (Cursor AI)

| Sesja | Status | Zakres |
|---|---|---|
| Sesja 1 (Manus) | ✅ | Fundament: struktura, pubspec, theme, routes, DailyPerspectiveWidget, MirrorMindService, SelfCompassionScreen |
| Sesja 2 (Cursor) | ✅ | Onboarding kroki 1–4: Disclaimer+AgeGate, Email Gate, RTS Assessment, Substancje |
| Sesja 3 (Cursor) | ✅ | Onboarding kroki 5–8: Data trzeźwości, Godzina przypomnienia, Kontakt alarmowy, Auth (anon→email/magic link) |
| Sesja 4 | ⏳ | HomeScreen + Check-in + Milestones |
| Sesje 5–20 | ⏳ | Pozostałe moduły |

### ⚠️ WYMAGANA AKCJA RĘCZNA — Anonymous Auth

**Supabase Dashboard → Authentication → Providers → Anonymous → Enable**

Bez tego `signInAnonymously()` w kroku 3 onboardingu zwróci błąd 400.
URL: `https://supabase.com/dashboard/project/kznhbcwozpjflewlzxnu/auth/providers`

### Konfiguracja Magic Link (Sesja 3)

```
Supabase Dashboard → Auth → URL Configuration → Redirect URLs:
Dodaj: io.supabase.flutter://login-callback/
```

Android `AndroidManifest.xml` — wymagany intent filter:
```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="io.supabase.flutter" android:host="login-callback" />
</intent-filter>
```

---

## 8. Znane Problemy / Uwagi

| Problem | Status | Akcja |
|---|---|---|
| `notify_users` używał `user_profiles` (nieistniejąca tabela) | ✅ Naprawiono — wdrożono v38 | — |
| Entitlement `pro` (lowercase) nie istniał | ✅ Naprawiono — `entlcd2ea18144` | — |
| Package name `com.soberstepsod.soberstepsod` w RevenueCat | ⚠️ Wymaga ręcznej zmiany | Dashboard → Apps → Edit |
| `DailyPerspectiveWidget` brak w kodzie | ✅ Zaimplementowano (Manus S1) | `lib/widgets/daily_perspective_widget.dart` |
| `SelfCompassionScreen` brak w kodzie | ✅ Zaimplementowano (Manus S1) | `lib/screens/self_compassion_screen.dart` |
| `MirrorMindService` brak hooków | ✅ Zaimplementowano (Manus S1) | `lib/services/mirror_mind_service.dart` |
| Anonymous auth wyłączone | ⚠️ Wymaga ręcznego włączenia | Dashboard → Auth → Providers → Anonymous |
| RLS `profiles_insert_own` nie obejmował anon | ✅ Naprawiono migracją 000002 | — |
| `email_leads` INSERT wymagał auth | ✅ Naprawiono migracją 000002 | Teraz działa bez auth (krok 2 onboardingu) |
| Leaked Password Protection wyłączone | ⚠️ Włącz w Supabase Auth Settings | Dashboard → Auth → Security |
