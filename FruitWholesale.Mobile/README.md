# Fruit Wholesale Mobile

Android client for the Fruit Wholesale Management System, with feature parity
to the Angular web app: auth, dashboard, all transaction modules (Supply,
Purchase, Collections, Supplier Payments, Daily Expenses, Employee Salary),
Stock, all three ledgers, reports, Masters CRUD, Settings, and Users. The
navigation drawer and the backend's `[Authorize(Roles=...)]` attributes
together enforce the same Admin/Manager/Accountant/Staff access matrix as the
web app — the backend is the real enforcement boundary, not the app UI.

## Running in development

```
flutter pub get
flutter run
```

`lib/core/config/api_config.dart` points at `http://10.0.2.2:5080` — the
Android emulator's alias for the host machine's `localhost`. Testing on a
physical device instead requires:
1. Starting the API with `--urls http://0.0.0.0:5080` so it accepts non-loopback connections.
2. Pointing `ApiConfig.baseUrl` at the host machine's LAN IP instead of `10.0.2.2`.
3. Adding that LAN IP as a `<domain>` entry in `android/app/src/main/res/xml/network_security_config.xml` (cleartext HTTP is only allowed for hosts listed there).

## Release builds

The release build is signed, and R8 shrinks/minifies/obfuscates the code
(`android/app/build.gradle.kts`, `android/app/proguard-rules.pro`).

**One-time setup** (already done for this repo's signing key, but documented
here for reference/recreation):

```
keytool -genkeypair -v -keystore android/app/fruit-wholesale-release.keystore \
  -alias fruitwholesale -keyalg RSA -keysize 2048 -validity 10000
```

Then create `android/key.properties` (git-ignored — never commit it):

```
storePassword=<keystore password>
keyPassword=<key password>
keyAlias=fruitwholesale
storeFile=fruit-wholesale-release.keystore
```

**⚠️ Back up `android/app/fruit-wholesale-release.keystore` and
`android/key.properties` somewhere safe outside this repo.** Android requires
every update to an installed app be signed with the *same* key. If this
keystore is lost, there is no recovery path — the app would have to be
republished under a new package ID, and every existing install would need to
be uninstalled and reinstalled from scratch.

**Building:**

```
flutter build apk --release              # single universal APK, for sideloading
flutter build apk --release --split-per-abi   # smaller per-architecture APKs
flutter build appbundle --release        # .aab, required for Play Store upload
```

Outputs land in `build/app/outputs/flutter-apk/` and
`build/app/outputs/bundle/release/`. If `android/key.properties` is missing
(e.g. a fresh clone without the private key), the release build silently
falls back to the debug signing key so `flutter run --release` still works
locally — that fallback build is **not** suitable for distribution.

Verify what a release build was actually signed with:

```
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
```
