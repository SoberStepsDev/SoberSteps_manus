# Release signing (Android)

## Polityka

- **`key.properties`** i pliki **`.jks` / `.keystore`** są **poufne** — nigdy w Gicie (patrz `.gitignore`). Wyjątek: szablon [`key.properties.example`](key.properties.example).
- **Upload key** Play Console to osobny sekret od **Play App Signing** — nie myl odcisków SHA-1 (por. [docs/LAUNCH_CHECKLIST.md](../docs/LAUNCH_CHECKLIST.md) oraz [scripts/verify_play_upload_key.sh](scripts/verify_play_upload_key.sh)).
- Buildy release na CI używają sekretów `KEYSTORE_*` — lokalnie trzymaj keystore poza repozytorium i backup poza maszyną deweloperską.
- Szczegóły zgłaszania problemów bezpieczeństwa: [SECURITY.md](../SECURITY.md).

## Utworzenie keystore (lokalnie)

```bash
cd android/app
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Skopiuj `../key.properties.example` do `../key.properties`, uzupełnij hasła i ścieżkę. Pliki `key.properties` i `*.jks` muszą pozostać poza commitem.
