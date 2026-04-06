# Cursor AI — Recovery+ Implementation Audit & Completion

## CONTEXT (nie generuj, tylko czytaj)

Projekt: Flutter/Dart + Supabase + RevenueCat.
Entitlement PRO: `customerInfo.entitlements['pro']?.isActive` (lowercase, case-sensitive).
Sprawdzaj zawsze przez `PurchaseProvider.isPro` lub `isPremium` (aliasy, oba istnieją).

## STAN ISTNIEJĄCY — NIE RUSZAJ

Poniższe mają już poprawny feature gate — **nie modyfikuj**:
- `lib/screens/naomi_screen.dart` — isPro gate ✓
- `lib/screens/craving_surf_screen.dart` — isPremium + soundscape picker ✓
- `lib/screens/return_to_self_screen.dart` — `AppConstants.returnToSelfProOnly` ✓
- `lib/screens/future_letter_write_screen.dart` — limit 1 listu free ✓
- `lib/screens/krytyk_patterns_screen.dart` — `ProGateWidget` ✓
- `lib/screens/milestones_screen.dart` — isPremium w celebration + TTS ✓
- `lib/screens/trigger_tracker_screen.dart` — isPremium lock ✓
- `lib/screens/accountability_screen.dart` — isPremium gate ✓
- `lib/screens/crash_log_screen.dart` — isPro dla save reflection ✓
- `lib/services/streak_protection_service.dart` — isPro guard ✓
- `lib/services/tts_service.dart` — isPremium dla milestone voice ✓
- `lib/widgets/pro_gate_widget.dart` — blur overlay + CTA ✓
- `lib/screens/paywall_screen.dart` — pełny paywall z A/B + FOMO timer ✓
- `lib/providers/purchase_provider.dart` — RevenueCat integration ✓

---

## ZADANIA DO WYKONANIA

### 1. Audit brakujących gatów (odczytaj plik, sprawdź, dodaj jeśli brak)

Dla każdego pliku poniżej: otwórz, sprawdź czy jest `isPro`/`isPremium` check lub `ProGateWidget`. Jeśli brak — dodaj minimalny gate zgodny z wzorcem z `accountability_screen.dart`.

**Pliki do sprawdzenia:**
- `lib/screens/karma_mirror_screen.dart` — Karma Mirror (wieczorna refleksja): PRO-only
- `lib/screens/savings_health_screen.dart` — Savings & Health kalkulacje 30-day: PRO-only
- `lib/screens/goals_screen.dart` — Goals & Rewards: PRO-only
- `lib/screens/mirror_moment_screen.dart` — Mirror Moment: PRO-only
- `lib/screens/experiment_screen.dart` — Self-Experiments CBT: PRO-only
- `lib/screens/x_marker_screen.dart` — X-Marker: PRO-only
- `lib/screens/krytyk_log_screen.dart` — Inner Critic log (zapis): PRO-only

**Wzorzec (użyj tego, nie twórz nowego):**
```dart
// Na początku build():
final isPro = context.watch<PurchaseProvider>().isPro;
if (!isPro) {
  return ProGateWidget(
    trigger: '<screen_name>_gate',
    child: const SizedBox.expand(),
  );
}
```
Lub dla screen z treścią do pokazania (preview blur):
```dart
// Wrap cały body:
return ProGateWidget(trigger: '<screen_name>_gate', child: <actualContent>);
```

---

### 2. Weryfikacja PremiumWelcomeScreen

Otwórz `lib/screens/premium_welcome_screen.dart`. Upewnij się że:
- [ ] Wyświetla nazwę planu (`purchase.planDisplayLabel(context)`)
- [ ] Zawiera listę 4 kluczowych benefitów (voice on Day 90, 3AM, letters, streak)
- [ ] Przycisk "Zaczynamy" → `Navigator.pushReplacementNamed(context, '/home')`
- [ ] Nie wywołuje żadnego API — dane tylko z `PurchaseProvider`

Jeśli brakuje — uzupełnij minimalnie.

---

### 3. Weryfikacja `AppConstants.revenueCatEntitlementId`

Otwórz `lib/constants/app_constants.dart`. Potwierdź:
```dart
static const String revenueCatEntitlementId = 'pro'; // lowercase!
```
Jeśli jest inaczej — popraw.

---

### 4. Weryfikacja `PurchaseService.initialize()`

Otwórz `lib/services/purchase_service.dart`. Upewnij się że:
- `Purchases.configure(PurchasesConfiguration(AppConstants.revenueCatApiKey))`
- Listener `Purchases.addCustomerInfoUpdateListener` aktualizuje stan (lub jest obsługiwany przez `refreshFromStore`)
- Brak hardcoded kluczy poza `AppConstants`

---

### 5. Spójność `isPro` vs `isPremium`

W `lib/providers/purchase_provider.dart` oba są aliasami (`isPro = _isPremium`). W całym `lib/` zamień wszystkie wywołania `isPremium` na `isPro` **tylko w nowo tworzonych/modyfikowanych plikach** — nie refaktoruj starych screensów masowo.

---

### 6. Weryfikacja upsell moments w milestone_upsell_modal.dart

Otwórz `lib/widgets/milestone_upsell_modal.dart`. Upewnij się że modal:
- Pojawia się przy dniach: 3, 7, 30, 90 (z `AppConstants.milestoneDays`)
- Używa `purchase.hasShownUpsell(day)` + `purchase.markUpsellShown(day)` żeby pokazać raz
- CTA → `Navigator.pushNamed(context, '/paywall', arguments: 'milestone_upsell_$day')`

---

## CZEGO NIE ROBIĆ

- Nie modyfikuj `pubspec.yaml`
- Nie modyfikuj migracji Supabase ani Edge Functions
- Nie zmieniaj `AppConstants.revenueCatApiKey` ani `supabaseAnonKey`
- Nie dodawaj nowych dependencies
- Nie twórz nowych wzorców feature-gating — używaj `ProGateWidget` lub wzorca z pkt 1
- Nie piszesz testów (osobne zadanie)
- Nie ruszaj plików oznaczonych "NIE RUSZAJ" powyżej

---

## WERYFIKACJA PO WYKONANIU

Dla każdego zmodyfikowanego pliku wpisz:
```
flutter analyze lib/<plik>.dart
```
Expected: 0 errors, 0 warnings (infos ignoruj).

Na końcu uruchom:
```
flutter analyze lib/ --no-fatal-infos
```
i pokaż output.

---

## DELIVERABLES

Lista zmodyfikowanych plików z jednolinijkowym opisem zmiany. Przykład:
```
lib/screens/karma_mirror_screen.dart — dodano ProGateWidget(trigger: 'karma_mirror_gate')
lib/screens/premium_welcome_screen.dart — uzupełniono listę benefitów + nawigacja
```
