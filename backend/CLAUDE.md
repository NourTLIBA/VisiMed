# VisiMed — Django backend

REST API for the field-CRM. DRF + a custom `User` (`AbstractUser` subclass).
SQLite locally, Postgres in prod. Deployed on **Render** — see `DEPLOY.md`.

## Run / verify

```bash
cd backend
python manage.py migrate
for c in seed_users seed_localities seed_products seed_visits backfill_targets; do python manage.py $c; done  # demo data
DJANGO_DEBUG=true python manage.py runserver
python manage.py test visimed      # gate — keep green
python manage.py check --deploy    # must be clean with a prod-like env
```

Demo logins after `seed_users`: `admin` / `admin123`, `manager1` / `manager123`,
`medrep1` / `med123`, `pharmrep1` / `pharma123`.

## Shape

| Area | File | Notes |
|---|---|---|
| Models | `visimed/models.py` | `User(role)` — `admin` / `manager` / `med_rep` / `pharma_rep`; `is_staff_role` = admin+manager. `VisitRecord.id` is a server-set `CharField` PK. `Objective` ships empty. |
| Access control | `visimed/visibility.py` | `visible_visits/doctors/pharmacies`, `managed_reps`. **Never re-implement scoping in a view** — call these. |
| Query filters | `visimed/filters.py` | `apply_visit_filters(qs, params)` — `date_from/date_to/wilaya/visit_type/potential/q/doctor/pharmacy`. Used by `GET /visits/` and the analytics endpoint; mirrors the frontend `VisitFilter`. |
| Demo gap-fill | `visimed/mock.py` | See below. |
| Auth | `visimed/authentication.py` | `ExpiringTokenAuthentication` (24 h TTL). `POST /auth/login/` is rate-limited (`ScopedRateThrottle`, scope `login`). `POST /auth/logout/` deletes the token. `GET /api/health/` is unauthenticated. |
| Views / URLs | `visimed/views.py`, `visimed/urls.py` | Analytics: `/dashboard/manager/`, `/dashboard/delegate/`, `/dashboard/delegate/analytics/`, `/dashboard/leaderboard/`, `/admin/kpis/`, `/alerts/`, `/analytics/map/`. |
| Settings | `config/settings.py` | Everything security-relevant is env-gated via `_env_bool(...)`; dev defaults are permissive, prod defaults are locked. `_TESTING` disables SSL redirect + throttles for the suite. |

## `DEMO_MOCK` (`visimed/mock.py`)

Env flag (`DEMO_MOCK`, default **off**; `render.yaml` sets it `true`). When on,
the analytics endpoints fill **empty** fields — a rep with no `Objective`, zero
orders/coverage, a zero coverage denominator, blank doctor/pharmacy contact
info — with plausible values. Stored rows are never touched.

**Coherence rule:** every synthesised number is a pure function of stable keys
(`mock._unit(*parts)` → SHA-256 → [0,1)), so the *same* metric is identical on
the délégué médical, délégué pharma and admin views:

- Objectives: `_weekly_visits_target(rep, week, actual)` is the one source; the
  delegate view reads it and `_objective_attainment` sums it over `managed_reps`
  → `manager.objective_attainment.target == Σ rep targets` (tested).
- Orders: `_rep_orders(rep_id, from, to)` — the manager dashboard sums it per
  rep when there are no real orders, so its total matches each Statistiques screen.
- Coverage denominator: synthesised from a scope-independent key → same
  everywhere; only the numerator varies with scope.
- Contact fields: `DoctorSerializer` / `PharmacySerializer.to_representation`
  call `mock.decorate_contact` — output only, never saved.

When adding a metric that can be empty: fill it through a shared helper keyed on
`(entity id, period, metric name)`, and if it also appears on an aggregate view,
aggregate the per-entity fills — don't synthesise the aggregate separately.

Turn `DEMO_MOCK` off once real data is being entered.

## Conventions

- New endpoints: scope via `visibility.py`, filter via `filters.py`, permission
  via `visimed/permissions.py` (`IsAdmin`, `IsManagerOrAdmin`, …).
- Passwords: `make_password` / `validate_password` only — never store plaintext.
  `User` uses Django's default PBKDF2.
- Tests live in `visimed/tests.py`; use `override_settings(DEMO_MOCK=True)` for
  mock-path tests.
- No new dependencies without cause (`requirements.txt` is short).
