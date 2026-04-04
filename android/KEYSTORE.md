# Release signing

```bash
cd android/app
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Copy `../key.properties.example` to `../key.properties`, fill passwords. Add `key.properties` and `*.jks` to .gitignore.
