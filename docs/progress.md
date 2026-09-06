# VisiMed Upgrade — Implementation Progress

> Anti-bloat checkpoint log. Updated after each milestone.

---

## Phase 0 — Project Bootstrap

| Checkpoint | Status | Notes |
|---|---|---|
| SRS reviewed | ✅ Done | Stack: Flutter + Django REST, RLS, streaming exports |
| Existing assets located | ✅ Done | CSV datasets in repo root |
| `progress.md` created | ✅ Done | This file |
| Backend scaffold | ✅ Done | `backend/` Django 6 + visimed app |
| Frontend scaffold | ✅ Done | `frontend/` Flutter with ValueNotifier state |
| DB migrations | ✅ Done | SQLite dev DB, PostgreSQL via env vars |
| Reference data seed | ✅ Done | 116 localities + demo users |
| End-to-end smoke test | ✅ Done | Login, visits, localities verified |

---

## Architecture Decisions (Lean)

- **Backend owns serialization** — PDF/CSV/XLSX generated server-side only.
- **SQLite for dev**, PostgreSQL-ready via `POSTGRES_*` env vars.
- **Token auth** — DRF `TokenAuthentication`, no JWT bloat.
- **No Celery/Redis** — synchronous streaming exports.
- **Flutter state** — `ValueNotifier` + `ListenableBuilder`, no provider/bloc.
- **Minimal deps** — `http`, `path_provider`, `table_calendar`, `flutter_map`, `uuid`.

---

## Project Layout

```
VisiMed/
├── backend/
│   ├── config/          # Django settings & root URLs
│   ├── visimed/         # Models, RLS views, export engines
│   ├── manage.py
│   └── requirements.txt
├── frontend/
│   └── lib/
│       ├── models/
│       ├── services/    # ApiService (REST + file download)
│       ├── state/       # AppState (ValueNotifier)
│       ├── screens/     # Login, visits, calendar, map, admin
│       └── theme/
├── Activity Report - Listes_items.csv
└── progress.md
```

---

## RBAC Implementation

| Feature | Admin | Med Rep | Pharma Rep |
|---|---|---|---|
| Rep CRUD | ✅ `/api/representatives/` | ❌ | ❌ |
| Global KPIs | ✅ `/api/admin/kpis/` | ❌ | ❌ |
| Visits | Read all | Write own (medical only) | Write own (pharma only) |
| Exports | Global scope | Self-scoped | Self-scoped |
| Calendar/Map | All visits | Own + assigned regions | Own + assigned regions |

Row isolation enforced in `VisitRecordViewSet.get_queryset()` and `BaseExportView.get_isolated_data()`.

---

## Demo Accounts

| Username | Password | Role |
|---|---|---|
| admin | admin123 | Admin |
| medrep1 | med123 | Medical Rep (Alger, Blida) |
| pharmrep1 | pharma123 | Pharma Rep (Oran, Mostaganem) |

---

## Run Instructions

### Backend (Step 1–3)

```powershell
cd backend
pip install -r requirements.txt
python manage.py migrate
python manage.py seed_users
python manage.py seed_localities
python manage.py runserver 8000
```

### Frontend (Step 4)

```powershell
cd frontend
flutter pub get
flutter run
# Android emulator:
flutter run --dart-define=VISIMED_API_URL=http://10.0.2.2:8000/api
# Production APK:
flutter build apk --release --split-per-abi
```

---

## Changelog

### 2026-07-07 — Session 1 (Complete)

- Created Django backend with custom `User`, `Locality`, `VisitRecord` models.
- Implemented RLS viewsets, token auth, admin KPI endpoint.
- Implemented CSV/XLSX/PDF export engines (openpyxl + reportlab).
- Added `seed_localities` and `seed_users` management commands.
- Created Flutter app: login, visits list, dynamic visit form, color-coded calendar, filterable map, admin panel.
- Seeded 116 communes from `Listes_items.csv`.
- API smoke test passed (login, visits, localities).

### 2026-07-07 — Session 2 (Complete)

- **Aesthetic Brand Revamp**: Embedded `other.png` logo and aligned app theme with premium navy-and-amber colors, clean card borders, custom font weight settings, and modern input decorations.
- **Improved Visit Form UI**: Re-organized form fields into clear visual groups with prefix icons, a custom tap-to-select date-picker row, and color-coded potential indicators.
- **Fixed Navigation & Sign-out**: Replaced standard stack back-popping with clean stack-clearing logic to avoid accessing authenticated areas after logging out, and fully reset filter states.
- **Corrected Map Filters**: Excluded `KOL` option from map view potential filters and implemented reactive animated chips via `ListenableBuilder`.
- **Fixed Admin KPIs**: Refactored backend queries to group and aggregate visit types and potentials cleanly using standard Django aggregation loops.
- **Enhanced Testing & Validation**: Built a realistic `seed_visits` management command generating 35 dummy visit records, fixed validation on empty email fields for pharmaceutical reps, and verified compiler linting.

---

## Codebase Analysis & Suggested Improvements

### 📱 Frontend (Flutter)
- **Local Cache & Offline Mode**: Representatives often log visits in hospitals or rural pharmacies with poor internet connectivity. Currently, if requests fail, data is lost. Adding a lightweight local storage database (e.g. `sqlite` or `hive`) to store visits locally and sync when back online is highly recommended.
- **Separation of Concerns**: State is managed via a single `AppState` class. As the application grows, consider grouping related notifiers (e.g. `VisitState`, `MapState`, `AdminState`) to minimize unnecessary UI rebuilds.
- **Geocoding & Accuracy**: Map screen currently uses mock static wilaya centroids with random offsets to position markers. Integrating a local database of coordinates or an offline geocoding helper will place visits on the map accurately.

### 🐍 Backend (Django REST Framework)
- **Database Index Optimization**: As the `vm_visit_records` table grows, add composite indexes on (`rep_id`, `date`) and (`wilaya`, `commune`) to keep viewsets and report generation quick.
- **Streaming & File Generation Offloading**: PDFs and Excel exports are currently built synchronously in memory. While fine for moderate data sets, generating massive global exports for admins will block the server thread. Offloading large exports to a background writer or streaming chunks is ideal as scale increases.

---

## Next Steps Roadmap

- [ ] **Offline Synchronization**: Implement local draft caching for offline visit logging.
- [ ] **Route Planner**: Single-tap GPS navigation/routing linking visits on the map.
- [ ] **Photo Attachment & Compression**: Allow representatives to attach pharmacy/doctor office photos with client-side scaling to save bandwidth.
- [ ] **Global Export Streaming**: Switch to chunk-based response streaming for massive data exports.

