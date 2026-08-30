# VisiMed — Architectural Inconsistencies & Flaws

_Audit date: 2026-08-30_

This document inventories the structural problems found while reading the whole
repository (Django REST backend under `backend/`, Flutter client under
`frontend/`). Items are grouped by severity. Each item notes **what** is wrong,
**where**, **why it matters**, and the **fix direction** taken in the
accompanying change set.

> Note: `Existing_problematics.pdf` in the repo root is unrelated to VisiMed (it
> describes container-terminal optimisation for another club project) and is
> ignored here.

---

## 1. Blocking / correctness bugs

### 1.1 The Flutter client no longer compiles for mobile or desktop
- **Where:** `frontend/lib/services/api_service.dart` lines 2–7.
- **What:** `import 'dart:html' as html;` is imported unconditionally, plus
  `import 'dart:io' hide File` and an unused `path_provider` import and unused
  `kIsWeb`. `dart:html` only exists on the web target, so `flutter build apk`,
  `ipa`, `windows`, `macos`, `linux` all fail to compile. The pubspec still
  targets Android/iOS (`android/`, `ios/` present, `MainActivity.kt` under
  `dz.visimed.visimed`).
- **Why it matters:** the product is a *field* CRM for delegates walking between
  clinics — a phone app. The current `main` branch can only be run as a web
  build.
- **Fix:** replace the direct `dart:html` use with a conditional import
  (`download_web.dart` / `download_io.dart` behind `download_stub.dart`) so the
  report download resolves to `AnchorElement` on web and to
  `path_provider` + `share_plus`/file write on IO.

### 1.2 Client-supplied primary key on `VisitRecord`
- **Where:** `backend/visimed/models.py` (`id = models.CharField(primary_key=True)`),
  `frontend/lib/screens/visit_form_screen.dart` (`id: const Uuid().v4()`),
  `serializers.py` (`id` is writable), `seed_visits.py`
  (`bulk_create(..., ignore_conflicts=True)`).
- **What:** the client invents the PK and the server trusts it. Two consequences:
  a malicious/buggy client can overwrite another record by guessing/replaying an
  id, and `ignore_conflicts=True` means a colliding POST is silently dropped —
  the API returns `201` with the *old* row's data.
- **Why it matters:** silent data loss and a write-authorization hole.
- **Fix:** server-generated UUID default (`default=uuid.uuid4`), `id` read-only in
  the serializer, client stops sending it.

### 1.3 `STATICFILES_STORAGE` is misspelled
- **Where:** `backend/config/settings.py` line 98: `STATICSFILES_STORAGE`.
- **What:** Django never reads this key, so WhiteNoise falls back to the plain
  (uncompressed, non-hashed) storage. `collectstatic` runs in every deploy
  (`Procfile`, `Dockerfile`, `render.yaml`) believing compression is on.
- **Fix:** rename to `STATICFILES_STORAGE`.

### 1.4 Two different access-control rules for the same data
- **Where:** `VisitRecordViewSet.get_queryset` (region OR own) vs
  `BaseExportView.get_isolated_data` (own only, no region).
- **What:** a med-rep browsing `/api/visits/` sees every visit in their assigned
  wilayas, but the CSV/XLSX/PDF export of "the same" list only contains their own
  visits. Admins get everything in both. The export and the screen disagree.
- **Why it matters:** users reasonably assume "export == what I see". Reports are
  silently incomplete.
- **Fix:** single `visible_visits(user)` helper used by the viewset and all three
  export views.

### 1.5 Region filter is substring matching on a free-text field
- **Where:** `VisitRecordViewSet._region_filter` — `Q(wilaya__icontains=region)`
  for each comma-split token of `user.assigned_regions`.
- **What:** `assigned_regions` is an unvalidated `TextField`. Real data
  (`Activity Report - Couverture délégués.csv`) looks like
  `"Ouest (Oran, Bel Abbès, Mostaganem)"` and
  `"Est 1 (constantine, Sétif, Mila, Batna), Est 3 (Bordj, Msila)"`. Splitting on
  `,` yields tokens like `"Ouest (Oran"` and `" Bel Abbès"` and `" Batna)"`, none
  of which `icontains`-match a wilaya name. Conversely a token like `"Alger"`
  matches `Alger` but the scheme is generally broken for the actual dataset.
- **Why it matters:** region-scoped visibility effectively does not work; a rep
  with a "region string" sees only their own visits (or, by accident, unrelated
  wilayas).
- **Fix:** introduce a real `Region`/`Territory` model with an explicit
  many-to-many of wilayas, or at minimum a normalized `assigned_wilayas`
  JSON/relation. The change set adds a `Territory` model and keeps the legacy
  string as a display-only fallback.

### 1.6 `/api/localities/` returns the entire table, twice, on every login
- **Where:** `LocalityViewSet` (`pagination_class = None`),
  `AppState.refreshAll` calls `fetchWilayas()` **and** `fetchLocalities()` back to
  back, and `VisitFormScreen` calls `loadCommunesForWilaya` which overwrites the
  global `localities` notifier.
- **What:** `Listes_items.csv` is the full commune list of Algeria (~1500+ rows).
  Every login downloads it in full twice, and the form's per-wilaya fetch mutates
  the same shared list the map/other screens read from.
- **Fix:** dedicated `/api/wilayas/` returning distinct names; keep localities
  paginated or filtered; store communes per-wilaya in a local cache map instead
  of clobbering the global list.

### 1.7 Login path duplicates token-expiry logic and can hand back a dead token
- **Where:** `AuthTokenView.post` re-implements the expiry check that
  `ExpiringTokenAuthentication.authenticate_credentials` already does; the two can
  drift. On the happy path `get_or_create` may return a token that is *exactly*
  at the boundary and the view's own check differs from the auth class's by the
  cost of the request round-trip.
- **Fix:** one helper `issue_fresh_token(user)` used by the login view; the auth
  class stays the single source of truth for "is this token still valid".

---

## 2. Missing domain model (blocks every requested feature)

The requested features — **doctor history**, **manager KPIs**, **delegate
leaderboard**, **coverage**, **alerts** — all assume entities that do not exist.
Today the schema has exactly three tables: `User`, `Locality`, `VisitRecord`.

### 2.1 There is no Doctor / Pharmacy entity
- **Where:** `VisitRecord` stores `target_name`, `gender`, `specialty`,
  `structure_type`, `address`, `wilaya`, `commune`, `telephone`, `email`,
  `potential`, `gco_status` **on every visit row**.
- **What:** a doctor visited five times is five unrelated rows with the name
  re-typed each time (`seed_visits.py` literally
  `random.choice(self.MED_DOCTORS)` per row; the real
  `Activity Report - Visit_Med.csv` has "Karim ZOURDANI" typed by hand). There is
  no identity, no dedupe, no "open the doctor's file".
- **Consequences:**
  - "Historique du médecin" (last visit, products, material, orders, remarks,
    objections, next action) is impossible — there is nothing to hang a history
    off.
  - "Couverture des médecins par rapport à la base de données totale" is
    impossible — there is no base of doctors to divide by.
  - "Nombre de nouveaux médecins visités" is impossible — no first-seen date.
  - Potential/GCO status are per-visit, so a doctor's current classification is
    "whatever the last person typed".
- **Fix:** add `Doctor` and `Pharmacy` models (identity, contact, classification,
  territory, `created_at`, `created_by`). `VisitRecord` gains nullable
  `doctor` / `pharmacy` FKs. A data-migration/backfill command clusters existing
  visits by normalized name+wilaya into `Doctor`/`Pharmacy` rows.

### 2.2 There is no Product catalogue and no "products presented"
- **Where:** the visit form has fixed integer counters (`qty_vials`,
  `qty_meters`, `qty_brochure_m`, `qty_brochure_patient`, `qty_affiche`,
  `qty_reader`).
- **What:** "produits présentés" is free-form in the spec but has nowhere to go;
  the counters conflate *promotional material handed out* with *products
  detailed*. "Matériel promotionnel distribué" (a manager KPI) is recoverable
  from the counters but "produits présentés" per visit is not.
- **Fix:** `Product` catalogue + `VisitProduct` join (`visit`, `product`,
  `presented` bool, `samples_qty`). Keep the material counters as-is for the
  "promo material distributed" KPI.

### 2.3 There is no Order / Prescription ("commande")
- **Where:** nothing.
- **What:** the client explicitly asks for "commandes obtenues (prescriptions)"
  on the doctor file, "commandes générées" as a manager KPI, and "pharmacie sans
  commande depuis une période" as an alert. None of it is representable.
- **Fix:** `Prescription` model (`visit`, `doctor`/`pharmacy`, `product`,
  `quantity`, `status`, `created_at`).

### 2.4 There is no Objective / target model
- **Where:** nothing. The client says "je n'ai pas encore eu les objectifs" —
  they expect to configure them later.
- **What:** "taux de réalisation des objectifs", "objectifs atteints" (delegate
  view), "objectif hebdomadaire non atteint" (alert), and the leaderboard's
  "taux d'atteinte des objectifs" criterion all need a target to divide by.
- **Fix:** `Objective` model (`rep`, `period_type` weekly/monthly, `period_start`,
  `visits_target`, `new_doctors_target`, `orders_target`, `coverage_target_pct`).
  Admin-editable; attainment computed against actuals. Ships empty (no fabricated
  numbers).

### 2.5 Structured visit outcome fields are missing
- **Where:** `VisitRecord.comment` is a single nullable `TextField`.
- **What:** the doctor file wants **remarques**, **objections**, and **prochaine
  action prévue** as distinct fields (the last one with a date, to drive the
  "next action due" logic and the calendar). One free-text blob cannot power
  alerts or the follow-up view.
- **Fix:** add `objections`, `next_action`, `next_action_date` to `VisitRecord`;
  keep `comment` as "remarques".

### 2.6 No "manager" persona
- **Where:** `UserRole` = `admin | med_rep | pharma_rep`.
- **What:** the spec talks about a "tableau de bord Manager" distinct from admin
  CRUD. Today the only elevated role is `admin`, which is also the Django
  superuser used for `/admin/`.
- **Decision:** treat `admin` as the manager for now (enhanced dashboard lives in
  the existing admin area) and leave a `MANAGER` role value reserved in the enum
  for a later split, rather than a disruptive migration now. Documented so it is a
  choice, not an oversight.

---

## 3. Analytics / dashboard weaknesses

### 3.1 `AdminKPIView` has no time dimension
- **Where:** `backend/visimed/views.py::AdminKPIView`.
- **What:** it returns lifetime totals only (`total_visits`, `total_vials`,
  `total_readers`, `by_visit_type`, `by_potential`, `active_reps`). The client
  wants **today / this week / this month**, average duration, coverage, new
  doctors, orders. None are computable from this endpoint and the Flutter
  `AdminKpis` model mirrors only these six fields.
- **Fix:** new `ManagerDashboardView` returning windowed counts + coverage +
  averages + material + orders + objective attainment; `AdminKPIView` kept for
  backwards compatibility.

### 3.2 KPIs are recomputed in three places with three definitions
- **Where:** `AdminKPIView` (server), `frontend/lib/data/demo_data.dart`
  (`kDemoKpis` recomputed in Dart), `admin_screen.dart::_StackedRatioBar`
  (re-buckets `by_visit_type` by `key.contains('med')`).
- **What:** the "medical vs pharma" split is derived by substring-sniffing the
  map keys on the client because the server sends `{"medical": n}` sometimes and
  display names other times. Fragile and duplicated.
- **Fix:** server returns already-bucketed, already-percented structures; client
  renders, does not re-bucket.

### 3.3 `addVisit` refetches the entire KPI payload
- **Where:** `AppState.addVisit` → `api.fetchAdminKpis()` after every create.
- **What:** an admin logging a visit triggers a full KPI recompute round-trip;
  reps do not (so their local `kpis` is stale anyway). Inconsistent and chatty.
- **Fix:** dashboards fetch on screen focus / pull-to-refresh; no implicit
  refetch coupled to `addVisit`.

### 3.4 No per-delegate rollup endpoint
- **Where:** nothing. `RepresentativeCRUDViewSet` is pure user CRUD.
- **What:** "tableau de bord des délégués" (visits today, objectives met) and the
  automatic ranking need per-rep aggregates. Building them client-side would mean
  downloading every visit for every rep.
- **Fix:** `DelegateStatsView` / `LeaderboardView` doing the aggregation in SQL.

### 3.5 Map data is fabricated
- **Where:** `frontend/lib/utils/geo.dart`.
- **What:** only 10 wilaya centroids are hardcoded; `resolveVisitPosition`
  offsets a marker by `commune.hashCode % 100 / 5000` (~a few hundred metres of
  noise). Any visit in one of Algeria's other 48 wilayas is dropped onto the
  geographic centre of the country `LatLng(28.03, 1.66)` — the Sahara. There is
  no per-wilaya/per-commune aggregation, so "secteurs bien couverts vs à
  renforcer" cannot be read off the map.
- **Fix:** ship a full 58-wilaya centroid table; add a `/api/analytics/map/`
  aggregate (count + reps + last visit per wilaya/commune) and render a
  graduated-symbol / choropleth-style overlay, not one pin per row.

### 3.6 No alerts engine
- **Where:** nothing.
- **What:** all four requested alerts (doctor not visited in N months, pharmacy
  with no order in a period, KOL not seen for a long time, weekly objective
  missed) need "now minus last-relevant-event" queries, which in turn need the
  Doctor/Pharmacy/Prescription/Objective entities from §2.
- **Fix:** `AlertsView` computing them on demand with configurable thresholds
  (query params), plus a `management/commands/run_alerts.py` for a future cron.

---

## 4. Security / configuration

| # | Where | Issue | Fix direction |
|---|-------|-------|---------------|
| 4.1 | `settings.py` | `SECRET_KEY` has an insecure in-code default; `DEBUG` defaults **true**; `ALLOWED_HOSTS` defaults `*` | Fail fast when `DJANGO_SECRET_KEY` unset and `DEBUG=false`; default `DEBUG` to false |
| 4.2 | `settings.py` | `CORS_ALLOW_ALL_ORIGINS = True` unconditionally (comment says "open for testing/tunneling") | Drive from `CORS_ALLOWED_ORIGINS` env; allow-all only when `DEBUG` |
| 4.3 | `Procfile` / `create_test_profiles.py` | Release phase creates `admin1 / medrep2 / …` with `password123` on every deploy, including prod | Gate behind an env flag; never seed weak creds in prod |
| 4.4 | `Procfile` release runs `create_test_profiles.py` but **not** `seed_users`; `seed_visits` expects `medrep1` / `pharmrep1` | Consolidate seeding into one idempotent command guarded by env |
| 4.5 | `RepresentativeCRUDViewSet.reset_password` | No password validation (`make_password(request.data['password'])` directly) — a 1-char password is accepted; `AUTH_PASSWORD_VALIDATORS` bypassed | Run `validate_password()` first |
| 4.6 | `settings.py` | `bypass-tunnel-reminder` header and localtunnel-specific plumbing are committed as if permanent | Move tunnel-only config out of committed settings |
| 4.7 | `authentication.py` | Expired token is `delete()`d during an unauthenticated request path — a race between two requests can 500 on `DoesNotExist` | `delete()` then raise, tolerate already-deleted |

---

## 5. Internationalisation

- **5.1 Half the UI is hardcoded English** despite a full `flutter_localizations`
  setup and `fr` being the template locale: `home_shell.dart`
  ("LOG VISIT", "Export report as", "Sign out"), `visit_form_screen.dart`
  ("Log Visit", "Doctor info", "Leave behind", "Structure et location" — itself
  fake French), `admin_screen.dart` ("Add rep", "KPIs", "New Representative",
  every dialog), `login_screen.dart` ("Welcome back", "Sign in to continue"),
  `map_screen.dart` ("All types", "Medical", "Pharma").
- **5.2 The ARB files are skeletal.** `app_fr.arb` has ~55 keys; the code
  references many more via `AppLocalizations.of(context)!` and even more strings
  are inline. `app_en.arb` / `app_ar.arb` were not audited for parity.
- **5.3 No RTL handling** even though Arabic is a supported locale
  (`Locale('ar')`), and `MaterialApp` has no `localeResolutionCallback`.
- **Fix direction:** add the new feature strings as proper keys in all three ARB
  files; migrate the most visible hardcoded strings. (Full i18n sweep is called
  out as follow-up — it is broad but mechanical.)

---

## 6. Frontend architecture

- **6.1 No navigation for detail views.** `visits_screen.dart` list items have
  `onTap: () {}  // placeholder for detail view`. There is no visit detail
  screen and therefore no entry point to a doctor file.
- **6.2 `AppState` is a hand-rolled bag of `ValueNotifier`s** with overlapping
  responsibilities: `refreshAll` toggles `loading` and swallows every error into
  a string; `login` calls `refreshAll` inside a `try/catch(_)` that hides data
  failures; `addVisit` mutates `visits.value` by allocating a new list each time.
  Works at this size but there is no request-in-flight de-dup, no retry, no
  cache invalidation story — every new dashboard/alert screen will bolt on its
  own ad-hoc notifier.
  - **Fix direction:** introduce a thin repository layer (`VisitRepository`,
    `DoctorRepository`, `DashboardRepository`) with typed load states; keep
    `ValueNotifier` but stop overloading one `loading`/`error` pair for the whole
    app.
- **6.3 `fetchVisits` silently truncates at the first page.** DRF paginates at
  `PAGE_SIZE = 100`; `fetchVisits` reads `data['results']` and never follows
  `next`. A delegate with >100 visits (a season's work) sees only the newest 100
  everywhere, including the map and calendar.
  - **Fix:** follow pagination, or add a `?all=1` / cursor endpoint for the
    client's "load my dataset" call.
- **6.4 Demo mode and live mode diverge.** `demo_data.dart` hardcodes
  `patientLoad: '31-60'` / `'61+'` while the form only offers `0-15 / 16-30 /
  30+`, and demo `structureType` values (`'Cabinet'`, `'Clinique privée'`,
  `'Hôpital public'`) are not in the form's dropdown lists (`'Cabinet Privé'`,
  `'CHU'`, `'Clinique'`). Editing a demo record would produce invalid dropdown
  state.
- **6.5 `resolveVisitPosition` uses `String.hashCode`** which is not stable
  across Dart releases / platforms — marker jitter is non-deterministic between
  builds.
- **6.6 Theme is named for the wrong style.** `AppTheme` comments say
  "The Jade Inari (Traditional, Mystical & Art Deco)" but the palette is a
  forest-green/jade Japanese theme; the login screen's custom painters are the
  only actually Art-Deco elements. The requested redesign should unify this into
  one deliberate Art-Deco system (geometric rules, symmetry, metallic accents,
  strong typographic hierarchy) applied through the theme, not per-screen
  painters.

---

## 7. Data / seeding integrity

- **7.1 `seed_visits.py` never sets `doctor`/`pharmacy`** (they will not exist
  until the migration) and picks names/wilayas independently at random, so the
  same "Dr. Karim Bensalem" gets contradictory specialties and wilayas across
  rows — actively harmful once dedup is introduced.
- **7.2 `seed_visits` writes `qty_meters` never** (it predates migration 0004)
  and `qty_reader` only for pharma, so the medical "meters remis" KPI is always
  zero in seeded data.
- **7.3 `Locality` PK is `code_commune`** which in the real CSV is `C-1`, `C-2`,
  … (a row number, not an INSEE-style code) and the CSV has a junk `Column 4`.
  `nom_commune` is frequently blank in `Visit_Med.csv`. Commune matching in the
  form (`l.nomWilaya == _wilaya`) is exact-string and will miss accented / spacing
  variants (`Alger-Centre` vs `Alger Centre`).
- **7.4 No `unique_together` anywhere** — nothing stops duplicate localities or
  (post-refactor) duplicate doctors.

---

## 8. Testing

- **8.1 One test file, two tests.** `backend/visimed/tests.py` covers login and a
  single visit create. No coverage for permissions/region isolation, exports,
  KPIs, or role validation in the serializer.
- **8.2 No frontend tests at all** (`flutter_test` is a dependency; there is no
  `test/` directory).
- **Fix direction:** add backend tests for the new endpoints and for the
  isolation helper; add at least a smoke `widgetTest` for the new dashboard.

---

## Summary of the change set that follows

| Area | Action |
|------|--------|
| Models | `Doctor`, `Pharmacy`, `Product`, `VisitProduct`, `Prescription`, `Objective`, `Territory`; new `VisitRecord` fields (`doctor`, `pharmacy`, `objections`, `next_action`, `next_action_date`); server-generated `id` |
| Migrations | one schema migration + one idempotent backfill command clustering existing visits into doctors/pharmacies |
| API | `DoctorViewSet` (+`/history/`), `PharmacyViewSet`, `ProductViewSet`, `ObjectiveViewSet`, `ManagerDashboardView`, `DelegateStatsView`, `LeaderboardView`, `AlertsView`, `MapAggregateView`, `/api/wilayas/` |
| Fixes | `STATICFILES_STORAGE`, unified visibility helper, password validation on reset, conditional `dart:html` import, pagination follow-through, deterministic geo, settings hardening |
| Frontend | Doctor file + visit-history timeline, Manager dashboard, Delegate dashboard + leaderboard, wilaya map aggregation, alerts feed, visit detail screen, Art-Deco design system, new ARB keys |
