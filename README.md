# VisiMed

Field CRM for the pharmaceutical **visite médicale**. Medical and pharmaceutical
sales reps log their visits to doctors and pharmacies; managers and admins get
dashboards, a leaderboard, coverage maps, automatic alerts and filter-aware
statistics.

- **Frontend** — Flutter (Android / iOS / web). `frontend/`
- **Backend** — Django + Django REST Framework, Postgres in production. `backend/`
- **Live web app** — https://nourtliba.github.io/VisiMed/ (GitHub Pages) · also Netlify
- **API** — `https://visimed-api.onrender.com/api` (the `visimed-api` Render service — deploy per `backend/DEPLOY.md`)

---

## Try it

### Web — works on any device, nothing to install

Open the Netlify site (`https://visimed.netlify.app`) or GitHub Pages
(`https://nourtliba.github.io/VisiMed/`). On a phone, *Add to home screen* for
an app-like PWA install.

**No Django server needed to try it.** The Netlify site also serves a **demo
API** at `/api` — a serverless function (`frontend/netlify/functions/api.mjs`)
that replays JSON captured from the real backend (`frontend/api-fixtures/`).
Login accepts the demo accounts; every screen works; writes aren't persisted.
The APK and GitHub Pages builds point at `https://visimed.netlify.app/api` by
default. To use the **real** backend instead, deploy it (`backend/DEPLOY.md`)
and set the `VISIMED_API_URL` repo secret to its URL.

### Android

1. Go to the **[latest release](https://github.com/NourTLIBA/VisiMed/releases/latest)**
   and download `visimed-<version>.apk`.
2. On the phone, allow your browser / files app to install apps
   (*Settings → Apps → Special access → Install unknown apps*).
3. Open the downloaded APK and install.

The APK is **debug-signed** (so it can be distributed without a Play Store
account) — Play Protect may warn about an "unrecognised developer"; that is
expected for a side-loaded build, choose *Install anyway*.

No release yet? Push a version tag or run the workflow:

```bash
git tag v1.0.0 && git push origin v1.0.0
```

…or **Actions → Release build → Run workflow**. It builds the APK + a web bundle
on GitHub's runners and attaches them to a GitHub Release (~5–8 min). See
[DOWNLOAD.md](DOWNLOAD.md) for details.

### iOS

There is no public iOS build — an installable iOS app needs an Apple Developer
account and TestFlight. Use the web app (Safari → Share → *Add to Home Screen*).

### Demo logins

| Role | Username | Password |
|---|---|---|
| Délégué médical | `medrep1` | `med123` |
| Délégué pharma | `pharmrep1` | `pharma123` |
| Manager | `manager1` | `manager123` |
| Admin | `admin` | `admin123` |

The login screen also has one-tap **Accès démo** buttons that load sample data
with no backend needed.

---

## Run locally

### Backend

```bash
cd backend
python -m venv .venv && . .venv/Scripts/activate     # or: source .venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
for c in seed_users seed_localities seed_products seed_visits backfill_targets; do python manage.py $c; done
DJANGO_DEBUG=true python manage.py runserver           # http://localhost:8000
```

SQLite is used automatically when `POSTGRES_NAME` is unset. `DEBUG` defaults to
**false**; set `DJANGO_DEBUG=true` for the browsable API and tracebacks.

Gate before pushing: `python manage.py test visimed` and
`python manage.py check --deploy` (with a prod-like env) must both be clean.

### Frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome \
  --dart-define=VISIMED_API_URL=http://localhost:8000/api
```

For an Android emulator use `http://10.0.2.2:8000/api`. With no `--dart-define`
the app targets the hosted Render API.

Gate before pushing: `flutter analyze` and `flutter build web` must both be
clean.

---

## Deployment

Both halves deploy from `main` via GitHub Actions.

| | Host | Workflow | Trigger |
|---|---|---|---|
| Web app **+ demo API** | Netlify (`deploy-frontend.yml`) — Flutter web at `/`, `netlify/functions/api.mjs` at `/api` | push to `main` under `frontend/**` |
| Web app | GitHub Pages (`nourtliba.github.io/VisiMed/`) — `pages.yml` | push to `main` under `frontend/**` |
| Release builds | GitHub Releases (`release.yml`) — APK + web zip | push a `v*` tag or run manually |
| Real backend (optional) | Render (`render.yaml` Blueprint + free Postgres) — `deploy-backend.yml` | push to `main` under `backend/**` → test → Render deploy hook |

The **demo API** on Netlify means the app works with no Django server. To run
the real backend, deploy it to Render (`backend/DEPLOY.md`) and set the
`VISIMED_API_URL` repo secret to its URL — the APK / Pages builds pick it up on
their next run. One-time for Pages: repo **Settings → Pages → Source → GitHub
Actions**.

One-time setup and every environment variable are documented in
**[backend/DEPLOY.md](backend/DEPLOY.md)**. Repo secrets: `VISIMED_API_URL`
(optional — set to a real backend URL to bypass the demo API),
`RENDER_DEPLOY_HOOK_URL`,
`NETLIFY_AUTH_TOKEN`, `NETLIFY_SITE_ID`.

### `DEMO_MOCK`

The Render deployment sets `DEMO_MOCK=true`: the analytics endpoints fill
*empty* fields (a rep with no objective, zero orders, blank contact info) with
plausible, mutually-consistent demo values so the three role views tell one
coherent story. It never alters stored data. **Set it to `false` once real data
is being entered.** See [backend/CLAUDE.md](backend/CLAUDE.md).

---

## Repository layout

```
frontend/            Flutter app
  lib/screens/        one file per screen; role-aware nav in home_shell.dart
  lib/state/          AppState (ValueNotifier only — no Provider/Bloc), VisitFilter
  lib/services/       api_service.dart (plain http)
  lib/theme/          app_theme.dart + deco.dart — the "warm clinical" design system
  lib/widgets/        filter_bar.dart, …
  tool/gen_logo.py    regenerates every icon from assets/images/logo.svg
  netlify/functions/api.mjs   the demo API (replays api-fixtures/)
  api-fixtures/       JSON captured from the real backend; tools/capture_fixtures.sh
  CLAUDE.md           frontend architecture + design system — read before UI work
backend/
  visimed/            the app: models, views, serializers, permissions
  visimed/visibility.py   single source of truth for data scoping
  visimed/filters.py      shared query-param filtering
  visimed/mock.py         DEMO_MOCK gap-filling
  config/settings.py      env-gated; permissive in DEBUG, locked in prod
  CLAUDE.md           backend architecture — read before API work
  DEPLOY.md           Render + Netlify setup, env vars
.github/workflows/   deploy-backend, deploy-frontend, pages, release
DOWNLOAD.md          end-user "try it" guide
inconsistencies.md   the 2026-08 audit; code comments reference its section numbers
data/                client source CSVs; `seed_localities` reads Listes_items.csv
docs/                background material (earlier notes, audit transcript, screenshots)
```

## Docs

| File | For |
|---|---|
| [README.md](README.md) | this — the front door |
| [DOWNLOAD.md](DOWNLOAD.md) | how end users get the app |
| [frontend/CLAUDE.md](frontend/CLAUDE.md) | frontend architecture + design system |
| [backend/CLAUDE.md](backend/CLAUDE.md) | backend architecture + the `DEMO_MOCK` rules |
| [backend/DEPLOY.md](backend/DEPLOY.md) | deployment, environment variables |
| [inconsistencies.md](inconsistencies.md) | the audit that drove the 2026-08 refactor |
