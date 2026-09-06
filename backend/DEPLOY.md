# Deploying VisiMed

Backend → **Render** (Django + managed Postgres). Frontend → **Netlify** (Flutter web).
Both deploy from `main` via GitHub Actions.

## Backend — one-time Render setup

1. **Create the services from the blueprint**
   - Push this branch to `main` (so `backend/render.yaml` is on the default branch).
   - Render Dashboard → **New → Blueprint** → pick the `VisiMed` repo → Apply.
   - Render reads `backend/render.yaml` and creates:
     - web service **`visimed-api`** (free, Frankfurt)
     - Postgres **`visimed-db`** (free, Frankfurt)
   - `DJANGO_SECRET_KEY` is generated automatically; the `POSTGRES_*` vars are
     wired from the database automatically.

2. **Set the one manual env var**
   - Render → `visimed-api` → **Environment** → `CORS_ALLOWED_ORIGINS`
     = your Netlify origin, e.g. `https://visimed.netlify.app`
     (no trailing slash; space- or comma-separate multiples).

3. **Wire CI-triggered deploys**
   - Render → `visimed-api` → **Settings → Deploy Hook** → copy the URL.
   - GitHub repo → **Settings → Secrets and variables → Actions → New secret**
     - `RENDER_DEPLOY_HOOK_URL` = that URL.
   - Now every push to `main` under `backend/**` runs the test job, then POSTs
     the hook (`.github/workflows/deploy-backend.yml`). `autoDeploy` is off in
     the blueprint so this is the only trigger.

4. **First deploy** runs the build command, which migrates and seeds
   (`seed_users`, `seed_localities`, `seed_products`, `backfill_targets` — all
   idempotent). Health check: `GET /api/health/`.

5. **Create your admin user** (Render → `visimed-api` → **Shell**):
   ```
   python manage.py createsuperuser
   ```

### Backend env vars (reference)

| var | value | notes |
|---|---|---|
| `DJANGO_SECRET_KEY` | *generated* | rotating it logs everyone out |
| `DJANGO_DEBUG` | `false` | never `true` in prod |
| `DJANGO_ALLOWED_HOSTS` | `.onrender.com` | leading dot = any subdomain |
| `DJANGO_CSRF_TRUSTED_ORIGINS` | `https://*.onrender.com` | for the Django admin |
| `CORS_ALLOWED_ORIGINS` | `https://<your-netlify>` | **set manually** |
| `POSTGRES_*` | *from `visimed-db`* | auto |
| `THROTTLE_LOGIN` | `10/min` (default) | login rate limit |
| `TOKEN_EXPIRED_AFTER_HOURS` | `24` (default) | API token TTL |
| `DJANGO_SECURE_SSL` | `true` (default when DEBUG=false) | set `false` only behind a proxy that can't do TLS |

## Frontend — Netlify

`.github/workflows/deploy-frontend.yml` builds with
`--dart-define=VISIMED_API_URL=…`. Set a repo secret **`VISIMED_API_URL`**
= `https://visimed-api.onrender.com/api` (falls back to that same value if the
secret is missing). Existing `NETLIFY_AUTH_TOKEN` / `NETLIFY_SITE_ID` secrets
are unchanged.

## Leaving Railway

`RAILWAY_TOKEN` secret can be deleted. The old `visimed-production.up.railway.app`
service can be shut down once Render is serving and the Netlify build has picked
up the new `VISIMED_API_URL`.

## Local

```bash
cd backend
python manage.py migrate
python manage.py seed_users        # demo users: admin/adminpass, medrep1/med123, …
python manage.py runserver
```
SQLite is used automatically when `POSTGRES_NAME` is unset. `DEBUG` defaults to
`false`; set `DJANGO_DEBUG=true` locally for the browsable API + tracebacks.
