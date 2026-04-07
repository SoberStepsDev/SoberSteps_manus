# Polityka zależności Flutter (`pub`)

## Cele

- Utrzymywać **aktualne, zweryfikowane** zależności w ramach constraintów z `pubspec.yaml`.
- Po każdej zmianie lockfile / pluginów: **ta sama wersja Flutter** co w CI (patrz `.github/workflows/*.yml`) i lokalnie (`flutter --version`).
- **Łatki bezpieczeństwa** (CVE, advisory od autora pakietu) mają pierwszeństwo przed rutynowym „upgrade wszystkiego”—najpierw minimalna bezpieczna wersja, potem pełny przegląd.

## Okresowy przegląd

**Co kwartał** lub **przed większym wydaniem** (oraz po merge’u dependabotów / ręcznym podbiciu wersji):

```bash
flutter pub get
flutter pub outdated
flutter pub upgrade   # tylko w ramach obecnych constraintów (^) w pubspec.yaml
flutter analyze --no-pub --congratulate
flutter test
```

- Zmiany w **`pubspec.lock`** i **`.flutter-plugins-dependencies`** commituj razem z `pubspec.yaml`, żeby CI i lokalne buildy były spójne.
- **Skoki majorowe** (np. Firebase 3→4, `app_links` 6→7, `fl_chart` 0.67→1.x) — **osobny PR**: changelog, breaking changes, test na urządzeniu / emulatorze tam gdzie dotyczy.

## Zgłaszanie problemów w zależnościach

- Podejrzenie podatności w łańcuchu dostaw: najpierw **[SECURITY.md](../SECURITY.md)** (prywatne zgłoszenie), bez publicznego issue z exploitem.
- Nie commituj **sekretów** ani pełnych `.env` — wzór: `assets/config.env.example`.

## Ostatni przegląd

- **2026-04-08:** polityka rozszerzona (cele, łatki, spójność z CI, SECURITY). Zalecamy ponowne uruchomienie `flutter pub outdated` przed kolejnym releasem; zsynchronizowany upgrade **FlutterFire** (`firebase_core` / `firebase_analytics` / `firebase_crashlytics`) nadal sensowny jako jeden PR po przeglądzie changelogów.
