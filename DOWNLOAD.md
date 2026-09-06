# Try VisiMed

## Web (any device — recommended)

**https://visimed.netlify.app**

Works in any modern browser. On a phone, use "Add to home screen" for an
app-like install (it's a PWA). Nothing to download.

## Android

1. Open the [latest release](https://github.com/NourTLIBA/VisiMed/releases/latest)
   and download `visimed-<version>.apk`.
2. On the phone, allow installs from your browser / files app
   (*Settings → Apps → Special access → Install unknown apps*).
3. Open the APK to install.

The build is **debug-signed** (no Play Store account needed to distribute it),
so Play Protect may show a "unrecognised developer" warning — that's expected
for a side-loaded APK; choose *Install anyway*.

## iOS

No public build — an installable iOS app needs an Apple Developer account and
TestFlight. Use the **web app** above (Safari → Share → Add to Home Screen)
in the meantime.

## Demo logins

| Role | User | Password |
|---|---|---|
| Délégué médical | `medrep1` | `med123` |
| Délégué pharma | `pharmrep1` | `pharma123` |
| Admin | `admin` | `admin123` |
| Manager | `manager1` | `manager123` |

The login screen also has one-tap **Accès démo** buttons that load sample data
with no network needed.

---

## Producing a build

- **Automated:** push a tag `vX.Y.Z` (or run *Actions → Release build → Run
  workflow*). `.github/workflows/release.yml` builds the APK + a web bundle and
  attaches them to a GitHub Release. Set the repo secret `VISIMED_API_URL` to
  point builds at a different backend.
- **Local APK:**
  ```bash
  cd frontend
  flutter build apk --release \
    --dart-define=VISIMED_API_URL=https://visimed-api.onrender.com/api
  # → build/app/outputs/flutter-apk/app-release.apk
  ```
- **Local web:** `flutter build web --release --dart-define=VISIMED_API_URL=...`
  → `build/web/` (the Netlify deploy does this on every push to `main`).

For a Play Store / App Store release you'd add real signing
(`android/key.properties` + a keystore, an iOS provisioning profile) — out of
scope for the "let people try it" builds above.
