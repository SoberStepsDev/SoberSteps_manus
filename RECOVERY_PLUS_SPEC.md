# Recovery+ (PRO) — Pełna specyfikacja subskrypcji

**Data:** 2026-04-06
**Status:** Opracowana na podstawie analizy kodu Flutter + RevenueCat

---

## 1. Podstawowe informacje

| Parametr | Wartość |
|---|---|
| **Nazwa produktu** | Recovery+ |
| **Entitlement ID (RevenueCat)** | `pro` (lookup_key: `pro`) |
| **Entitlement Display Name** | Recovery+ |
| **Produkt ID na Google Play** | `sobersteps_monthly_699`, `sobersteps_annual_5999`, `sobersteps_family_999`, `sobersteps_lifetime_8999` |

---

## 2. Dostępne plany cenowe

### Monthly (Miesięczny)
- **Cena:** €6.99/miesiąc
- **Product ID:** `sobersteps_monthly_699`
- **Lookup Key (RevenueCat):** `$rc_monthly`
- **Typ:** Subscription
- **Automatyczne odnowienie:** Tak, anulowalne 24h przed odnowieniem

### Annual (Roczny) ⭐ BEST VALUE
- **Cena:** €59.99/rok
- **Product ID:** `sobersteps_annual_5999`
- **Lookup Key (RevenueCat):** `$rc_annual`
- **Typ:** Subscription (default, najczęściej rekomendowany)
- **Automatyczne odnowienie:** Tak, anulowalne 24h przed odnowieniem
- **Badge:** "BEST VALUE" (wyróżniony na paywall'u)

### Family (Rodzinny)
- **Cena:** €9.99/miesiąc
- **Product ID:** `sobersteps_family_999`
- **Lookup Key (RevenueCat):** `$rc_custom_family`
- **Typ:** Subscription
- **Automatyczne odnowienie:** Tak
- **Cechy:** Możliwość dodania obserwatorów rodzinnych (Family Observers)

### Lifetime (Na zawsze)
- **Cena:** €89.99 (jednorazowo)
- **Product ID:** `sobersteps_lifetime_8999`
- **Lookup Key (RevenueCat):** `$rc_lifetime`
- **Typ:** One-time purchase
- **Widoczność:** Dostępny dopiero po 90+ dniach od instalacji
- **Automatyczne odnowienie:** Brak (jednorazowy zakup)

---

## 3. Promocja / Trial

- **Darmowy trial:** 7 dni
- **Dla nowych użytkowników:** Automatycznie oferowany
- **Dostęp:** Pełny dostęp do wszystkich Recovery+ features podczas trialui
- **Po trial:** Automatyczne przejście na wybrany plan, chyba że zostanie anulowany 24h przed końcem

---

## 4. Ekskluzywneprzytki (cechy PRO)

### 4.1 Naomi AI (AI Coach)
- **Status:** Dostępny **TYLKO w Recovery+**
- **Opis:** AI coach, który pyta — nigdy nie osądza
- **Funkcjonalność:**
  - Rotacyjne pytania z czterech obszarów: współczucie, ciekawość, ciało, ja z przyszłości
  - Spersonalizowane feedbacki (Naomi-feedback Edge Function)
  - Rate limit: 1 pytanie na sesję (chroniąc przed nadużyciem)
  - Generuje refleksyjne pytania na podstawie odpowiedzi użytkownika
- **Inicjator uplift:** Widoczny na milestone'u dnia 7 (7-day upsell)

### 4.2 Głos Naomi na milestones (Milestone Voice Messages)
- **Status:** Dostępny **TYLKO w Recovery+**
- **Opis:** Nagrany głos (ElevenLabs voice ID: `2Hw5QTX3wstf1sLYfhhk` — głos Patryka)
- **Trigger:** Osiągnięcie milestone'u (np. dzień 90)
- **Obsługiwane milestone'y:** 1, 3, 7, 14, 30, 60, 90, 180, 365, 730, 1825 dni
- **Funkcjonalność:** Odtwarzanie spersonalizowanego komunikatu dla każdego milestone'u
- **Uplift:** "Imagine hearing my voice on Day 90" (paywallBenefit1)

### 4.3 Soundscapes do Craving Surf
- **Status:** Dostępny **TYLKO w Recovery+**
- **Opis:** Pełny dostęp do soundscapes'ów do sesji Craving Surf
- **Funkcjonalność:**
  - Sesje surfowania na głodzie (craving_surf_sessions)
  - Otoczenie dźwiękowe wspomagające zaangażowanie
  - Bez limitu sesji
- **Free tier:** Ograniczony dostęp do soundscapes
- **Uplift:** "Unlock full soundscapes with Recovery+" (cravingUnlockSoundscapes)

### 4.4 Streak Protection (Ochrona Streaka)
- **Status:** Dostępny **TYLKO w Recovery+**
- **Opis:** Przywrócenie streaka w przypadku poślizgu
- **Funkcjonalność:**
  - Jeśli użytkownik przezyje ciężką noc (3 AM Wall trigger), streak jest chroniony
  - Umożliwia powrót bez utraty postępu
  - Psychologiczna ochrona przed upadkiem motywacji po jednej ciężkiej nocy
- **Uplift:** "Don't let one hard night destroy your streak" (paywallBenefit4)

### 4.5 Listy do siebie — rozszerzony dostęp
- **Status:** Dostępny **TYLKO w Recovery+** (rozszerzona funkcja)
- **Opis:** Możliwość pisania listów do przyszłych wersji siebie
- **Funkcjonalność:**
  - Unlimited letters (Free: max 1 aktywny list)
  - Scheduled delivery na przyszłą datę
  - Notyfikacja przy dostarczeniu
  - Integracja z Naomi AI feedback
- **Uphift:** "Write a letter to yourself in 6 months" (paywallBenefit3)
- **Premium letters:** Notyfikacja + wiadomość od Naomi przy dostarczeniu

### 4.6 Naomi Voice w Letters (Naomi feedback na listy)
- **Status:** Dostępny **TYLKO w Recovery+**
- **Opis:** AI feedback na listy do przyszłości
- **Funkcjonalność:**
  - Po napisaniu listu, Naomi generuje refleksyjne pytanie
  - Wspiera głęboką pracę wewnętrzną
  - Edge Function: `naomi-feedback` (rate limited)

### 4.7 Reflections (Refleksje) — Zachowywanie
- **Status:** Dostępny **TYLKO w Recovery+**
- **Opis:** Możliwość zapisywania refleksji (daily perspective notes)
- **Funkcjonalność:**
  - Save reflection (saveReflection)
  - Upgrade required prompt: "Upgrade to PRO to save reflections"
  - Daily reflection questions (CrashLog module)
  - Archive dostępu do wcześniejszych refleksji
- **Free tier:** Możliwa lektura/pisanie, ale bez opcji zapisu

### 4.8 Return to Self — Rozszerzony dostęp
- **Status:** Niektóre ścieżki **TYLKO w Recovery+**
- **PRO-only paths:**
  - `perfectionism` (Perfekcjonizm)
  - `toxic_relationships` (Toksyczne Relacje)
- **Free paths:**
  - `self_hatred` (Nienawiść do siebie) — dostępny dla wszystkich
- **Funkcjonalność:**
  - 30-day guided paths (30-dniowe ścieżki)
  - Daily mirror exercises
  - Self-compassion tools (Inner Critic reframing, Self-Compassion Experiments, X-Marker)
  - RTS scores tracking

### 4.9 Analiza nastrojów — rozszerzona
- **Status:** Dostępny **TYLKO w Recovery+**
- **Opis:** Zaawansowana analityka nastroju
- **Funkcjonalność:**
  - 30-day mood charts (Unlock 30-day charts with Recovery+)
  - Mood analysis by weekday (daily patterns)
  - Heatmap trends
  - Craving patterns
  - Trigger analysis (na podstawie zapisanych triggers)

### 4.10 Inner Critic Tools (Narzędzia do pracy z krytykiem wewnętrznym)
- **Status:** Dostępny **TYLKO w Recovery+**
- **Opis:** 5-card CBT self-compassion module
- **Karty/Tools:**
  1. **Inner Critic (Krytyk)** — Logowanie krytycznych myśli + reframing na ciekawość
  2. **Self-Experiments (Eksperymenty)** — 3-day behavioral experiments
  3. **X-Marker (Znacznik)** — Daily self-care tracking
  4. **Karma/Evening Reflection** — Evening perspective questions
  5. **RTS (Return to Self)** — 30-day guided healing paths
- **Funkcjonalność:**
  - Hourly heatmap (24-hour patterns)
  - 14-day trends
  - Reframing prompts (5 different approaches)
  - Local data storage (na urządzeniu)

### 4.11 Accountability Partner (Partner Odpowiedzialności)
- **Status:** Dostępny **TYLKO w Recovery+** (rozszerzona wersja)
- **Opis:** Pełna funkcjonalność partnera odpowiedzialności
- **Cechy:**
  - Pairing via code lub email
  - Shared streak (soft motivation x2)
  - Private encrypted chat
  - Notifications when partner checks in
  - Shared milestones & moments visibility
  - Family Observers integration

---

## 5. Cechy FREE (brak PRO)

### Dla porównania — co jest w Free:
- ✅ Daily check-ins (mood, craving level, triggers)
- ✅ Milestone tracking
- ✅ 3 AM Wall (crisis moments)
- ✅ Craving Surf (limited soundscapes)
- ✅ Future letters (max 1 active)
- ✅ Community (posts, likes)
- ✅ Basic notifications
- ✅ Self-Hatred RTS path (first path only)
- ✅ Meetings & support directory
- ✅ Basic analytics
- ❌ Naomi AI (PRO only)
- ❌ Milestone voice messages (PRO only)
- ❌ Full soundscapes (PRO only)
- ❌ Streak Protection (PRO only)
- ❌ Perfectionism & Toxic Relationships RTS paths (PRO only)
- ❌ Reflection saving (PRO only)
- ❌ Advanced analytics (PRO only)

---

## 6. Upsell Moments (Promocyjne momenty w aplikacji)

| Milestone | Trigger | Komunikat |
|---|---|---|
| Day 7 | Osiągnięcie dnia 7 | "Write a letter to yourself for 30 days out. Naomi AI will be with you in hard moments." |
| Day 3 | Osiągnięcie dnia 3 | "Recovery+ unlocks Streak Protection — your progress stays safe even when you slip." |
| Day 30 | Osiągnięcie dnia 30 | "Unlock Naomi's voice, letters to your future self, and the full self-compassion module." |
| Day 90 | Osiągnięcie dnia 90 | "Your brain has rewired. Recovery+ gives you tools for the next stage of the path." |
| Craving Surf | Brak pełnych soundscapes | "Unlock full soundscapes with Recovery+" |
| Naomi AI | Próba korzystania z Naomi | "Naomi is available in Recovery+" |
| RTS PRO paths | Próba dostępu | "This path will be part of Recovery+ when it's ready" |
| 30-day analytics | Próba przeglądania | "Unlock 30-day charts with Recovery+" |

---

## 7. Warunki biznesowe

| Parametr | Wartość |
|---|---|
| **Okres rozliczeniowy** | Monthly, Annual, Lifetime |
| **Automatyczne odnowienie** | Tak (Monthly, Annual) / Nie (Lifetime) |
| **Anulacja** | Store (Google Play/App Store) — 24h przed odnowieniem |
| **Restore Purchases** | Wbudowana funkcja w ProfileScreen |
| **Trial period** | 7 dni (free) |
| **Entitlement format** | RevenueCat `pro` (lowercase) |
| **Check-in:** | `customerInfo.entitlements['pro']?.isActive ?? false` |

---

## 8. Implementacja w Flutter

### Sprawdzenie czy user jest PRO:
```dart
bool isPro = customerInfo.entitlements['pro']?.isActive ?? false;
// lub alias:
bool isPro = purchase.isPro; // z PurchaseProvider
```

### Return to Self PRO-only check:
```dart
const Set<String> returnToSelfProOnly = {
  'perfectionism',
  'toxic_relationships',
};

// Feature gate:
if (returnToSelfProOnly.contains(selectedPath) && !isPro) {
  showPaywall();
}
```

### Paywall trigger:
```dart
await Navigator.pushNamed(context, '/paywall', arguments: {'trigger': 'naomi_access'});
```

---

## 9. Pricing tiers summary

| Plan | Cena | Okres | Best For |
|---|---|---|---|
| Monthly | €6.99 | /miesiąc | Spróbować przed rocznym |
| **Annual** | €59.99 | /rok | **Najlepszy deal (~€5/miesiąc)** |
| Family | €9.99 | /miesiąc | Parę + Family Observers |
| Lifetime | €89.99 | jednorazowo | Power users (po 90+ dniach) |

---

## 10. Paywall messaging

### Benefit Cards (4 główne korzyści):
1. 🎤 "Imagine hearing my voice on Day 90"
2. 🌙 "At 3 AM — 847 people have been here"
3. 📮 "Write a letter to yourself in 6 months"
4. 🛡️ "Don't let one hard night destroy your streak"

### Social Proof:
- "Join 12,847 people on the road to recovery"

### Headlines (A/B variants):
- **Variant A:** "Unlock Recovery+ — Free for 7 Days" (default, recommended)
- **Variant B:** "847 people started today. Join."
- **Variant C:** "Your day 30 deserves a voice."

---

## 11. Notatki implementacyjne

- ✅ Entitlement key: `pro` (case-sensitive!)
- ✅ RevenueCat lookup_key: `pro` (lowercase)
- ✅ Trial automatic for new users (7 days)
- ✅ Free 7-day trial + immediate feature unlock during trial
- ✅ Lifetime invisible until day 90+ (prevent impulse buys)
- ✅ Annual is default selected on paywall
- ⚠️ RLS policies must protect PRO-only data
- ⚠️ Naomi AI rate-limited (429 on Edge Function)
- ⚠️ Voice files stored in `assets/audio/milestones/`

---

**Status:** Kompletna specyfikacja dla Dev/Product team
**Ostatnia aktualizacja:** Cursor AI sesja analityczna
