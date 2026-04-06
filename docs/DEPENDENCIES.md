# Zależności Flutter (`pub`)

## Okresowy przegląd

Co kwartał (lub przed większym releasem):

```bash
flutter pub outdated
flutter pub upgrade        # w ramach obecnych constraintów w pubspec.yaml
flutter analyze && flutter test
```

Majorowe skoki (np. Firebase 3→4, `app_links` 6→7, `fl_chart` 0.67→1.x) wymagają osobnego PR: przeczytaj changelog pakietów, sprawdź breaking changes i regresję na urządzeniu.

## Ostatni przegląd

- **2026-04-06:** `flutter pub outdated` — bez podbicia majorów; zależności bezpośrednie są na najnowszych wersjach dozwolonych przez `pubspec.yaml` (`^`). Kolejny sensowny krok to zsynchronizowany upgrade **FlutterFire** (`firebase_core` / `firebase_analytics` / `firebase_crashlytics`) w jednym commicie.
