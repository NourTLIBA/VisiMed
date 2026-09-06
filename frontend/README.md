# VisiMed — frontend

Flutter app (Android / iOS / web). See the repo root
**[README](../README.md)** for what VisiMed is, how to try it, and how to
deploy.

## Quick start

```bash
flutter pub get
flutter run -d chrome --dart-define=VISIMED_API_URL=http://localhost:8000/api
```

- Android emulator → `http://10.0.2.2:8000/api`
- No `--dart-define` → targets the hosted Render API
  (`https://visimed-api.onrender.com/api`)

Gate before pushing: `flutter analyze` and `flutter build web` clean.

## Architecture & conventions

**[CLAUDE.md](CLAUDE.md)** — screen map, the `ValueNotifier`-only state model,
the shared `VisitFilter`, and the "warm clinical" design system
(`lib/theme/app_theme.dart` + `lib/theme/deco.dart`). Read it before touching
the UI.

App icons are generated from `assets/images/logo.svg` by `tool/gen_logo.py`
(Pillow only) — never hand-edit the PNGs.
