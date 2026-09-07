# VisiMed — Flutter frontend

Field CRM for pharmaceutical **visite médicale**: medical & pharma sales reps log
visits to doctors / pharmacies; managers and admins get dashboards, a leaderboard,
coverage maps and automatic alerts. Not a patient-facing app.

> A warm-neutral, deliberately unfussy visual rebuild landed on 2026-09-06
> (branch `main`). This file is the map for anyone touching the UI next.

---

## Run / verify

```bash
cd frontend
flutter analyze          # must be clean (gate)
flutter build web        # must succeed (gate)
flutter run -d chrome    # manual check
```

- No network needed for analyze/build once `.dart_tool/` is populated; prefix
  with `PUB_OFFLINE=true` and pass `--no-pub` if offline.
- **Demo mode**: the login screen has "Accès démo" buttons (Admin / Médical /
  Pharma) that load `lib/data/demo_data.dart` with **zero network calls**. Use
  this to review every screen without a backend. Real login hits
  `lib/services/api_service.dart` (Django backend under `../backend`).
- Credentials pre-filled on the login field: `medrep1` / `med123`.

---

## Architecture (unchanged by the redesign)

| Concern | Where | Notes |
|---|---|---|
| Entry | `lib/main.dart` | `MaterialApp`, `AppTheme.light()`, locale from `AppState`. |
| State | `lib/state/app_state.dart` | **`ValueNotifier` only** — no Provider/Riverpod/Bloc. Screens use `ValueListenableBuilder` / `ListenableBuilder`. Keep it that way. |
| API | `lib/services/api_service.dart` | Plain `http`. Token in memory. Base URL: `--dart-define=VISIMED_API_URL=…`. Netlify build → `/api` (same-origin; the site serves a **demo API** — `netlify/functions/api.mjs` replaying `../api-fixtures/`). APK / GitHub Pages builds → an absolute URL, default `https://visimed.netlify.app/api`, overridable via the `VISIMED_API_URL` repo secret to point at the real Django backend (`../backend/DEPLOY.md`). `report_download*.dart` is the conditional-import web/io split for exports. |
| Models | `lib/models/models.dart` | Enums `UserRole {admin, manager, medRep, pharmaRep}`, `VisitType {medical, pharmaceutical}`, `TargetPotential {KOL, A, B, C}`. `AppUser` has `isStaff / isAdmin / isManager / isMedRep / isPharmaRep / defaultVisitType`. |
| l10n | `lib/l10n/app_*.arb` → generated `app_localizations*.dart` | fr (template) / en / ar. `flutter gen-l10n` regenerates. Strings are **partly** localised — many screen labels are still hard-coded French. If you add UI copy, prefer adding an ARB key, but matching the file you're in (hard-coded FR) is acceptable for now. |
| Navigation | imperative `Navigator.push(MaterialPageRoute(...))` | no router package. |

### Screen map

`login_screen` → `home_shell` (role-aware `NavigationBar`):

- **rep** (medRep / pharmaRep): Visites · Agenda · Médecins · Carte · **Perf
  (`stats_screen.dart`, `embedded: true`)**. FAB "Nouvelle visite" on tab 0.
- **manager**: Dashboard · Équipe (leaderboard) · Médecins · Carte · Alertes.
- **admin**: Dashboard · Admin (`admin_screen`) · Médecins · Carte · Alertes.

Detail screens: `visit_detail_screen`, `doctor_detail_screen`,
`manager_dashboard_screen`, `stats_screen` (`StatsScreen` — pushed by
`team_screen`'s leaderboard sheet with a `repId` for the manager view),
`team_screen` (`LeaderboardScreen`, `DelegateStatsBody`, `_DelegateSheet`).

### Shared visit filters (`state/filters.dart` + `widgets/filter_bar.dart`)

`VisitFilter` (range / wilaya / type / potentials / query) lives on
`AppState.visitFilter` (a `ValueNotifier`, reset on logout). `FilterBar` — preset
chips (`FilterPreset`: Cette semaine / Ce mois / 90 j / Mes KOL) + a "Filtres"
bottom sheet — reads and writes it. It's mounted on **Visites**, **Médecins**
and **Statistiques**; the filter persists across those screens by design.

- Client-side: `state.filteredVisits` applies `VisitFilter.matches` (on top of
  the map's older `potentialFilter` / `typeFilter`). Médecins applies only the
  `wilaya` + `potentials` facets (a doctor isn't a visit).
- Server-side: `VisitFilter.toQuery()` → the backend's shared params
  (`date_from` / `date_to` / `wilaya` / `visit_type` / `potential` / `q`),
  consumed by `GET /visits/` and `GET /dashboard/delegate/analytics/`.

`StatsScreen` (`fetchDelegateAnalytics`) re-fetches whenever `visitFilter`
changes. Like the other analytics screens it needs the live backend — demo mode
shows its error state.

---

## Design system — "warm clinical"

The old theme was a dark forest-green + brushed-gold **Art-Deco** kit
(corner-tick painters, sunbursts, `ALL CAPS` spaced headers, `w900`). It was
replaced because it read as over-decorated. The new language:

- **Ground**: warm ivory `AppTheme.surface (#F4F1EA)`. Grouped strips use
  `surfaceAlt (#EDE8DD)`.
- **Cards**: pure white, radius `20`, **one diffuse shadow** (`AppTheme.softShadow`),
  **no borders, no ornaments**. Inset rows (steppers) use `Deco.soft()` (flat tint,
  no shadow).
- **Brand**: `primary` muted pine `#2F5D50`; `jade #3E7C63` secondary green;
  `accent` warm clay `#C2795A` (used sparingly — selected date, pharma, one-off
  emphasis). `gold #B8975F` survives only as a muted-tan legacy accent (dashboard
  gauges, #1 leaderboard medal). **Don't reintroduce bright gold or hairline
  outlines on cards.**
- **Text**: `ink #2B2A26` / `inkMuted #6E6C64` / `inkFaint #9C9A8F`. Hairline
  `#E7E2D7` for the rare divider.
- **Semantic**: `success` green, `warning` amber `#C98A3C`, `danger` warm brick
  `#B4472E` (aliased as `vermillion` / `KOLAccent` for old call sites).
- **Type**: default `Roboto`. Sentence case everywhere. **No `.toUpperCase()` on
  labels/titles/buttons. No `letterSpacing` above ~0.2. Nothing heavier than
  `w700`** (titles `w600`, emphasis `w600`, body `w400`). Screen title 20, section
  title 15, card title 14–16, body 14, caption 12–13.
- **Radius tokens**: `AppTheme.rCard 20` · `rTile 16` · `rField 14` · `rPill 999`.
- **Shape**: prefer circles / full pills over rounded-squares for avatars, chips,
  badges, segmented controls.

### Files

- **`lib/theme/app_theme.dart`** — all colour/shape tokens + the full `ThemeData`
  (AppBar, Card, inputs, buttons, `NavigationBar`, chips, dialogs, sheets,
  snackbars, `TabBar`, progress). Most screens get their look from here alone.
  `AppTheme.softShadow` is the single elevation. Helpers: `visitTypeColor`,
  `potentialAccent`.
- **`lib/theme/deco.dart`** — shared widget kit. **Class names are frozen** so
  screens didn't need structural edits:
  - `DecoCard({child, padding, onTap})` — the standard white panel.
  - `DecoSectionTitle(text, {icon, trailing})` — quiet header, sentence case.
  - `DecoStat({label, value, sub, icon, color, width})` — KPI tile.
  - `DecoChip(label, {color, filled, icon})` — full pill.
  - `DecoGauge({value, label, centerText, color, size})` — clean ring, no ticks.
  - `DecoBarRow({label, value, total, color, valueLabel})` — labelled progress.
  - `DecoAvatar(text, {color, size})` — round initials monogram (**new**).
  - `DecoEmpty({icon, title, message})` — centred empty/placeholder state (**new**).
  - `Deco.panel()` / `Deco.soft()` / `Deco.potentialColor()` /
    `Deco.severityColor()` / `Deco.orderStatusColor()` / `Deco.forest` (login
    hero gradient only).

If you need a new shared surface, add it to `deco.dart` — don't hand-roll
`BoxDecoration(border: …)` in a screen.

---

## Conventions & gotchas

- **Colours**: always `AppTheme.*` tokens. `.withAlpha(int)` is the house style
  (not `withOpacity` / `withValues`) — the codebase targets a Flutter old enough
  that `withValues` isn't guaranteed. Rough alpha map: 6%→15, 8%→20, 10%→26,
  12%→31, 16%→41, 22%→56.
- **Dates**: `MaterialLocalizations.of(context).formatShortDate(d)` for display.
  Avoid `package:intl`'s `DateFormat` with a locale — date-format data isn't
  initialised and it throws for fr/ar.
- **Icons**: outlined variants for idle, filled for selected `NavigationDestination`.
- **`AppTheme.primaryDark`** still exists (`#24463D`) but is now only a slightly
  darker green; screen text should use `AppTheme.ink`.
- **`visit_form_screen`** keeps green (`AppTheme.jade`) prefix-icons on inputs by
  intention — consistent field affordance. The global input theme's
  `prefixIconColor` is `inkFaint` for screens that don't override.
- **`admin_screen` `_CompactMetric`** row sits in a `SingleChildScrollView`
  (`Clip.hardEdge` by default) — its `softShadow` can be clipped top/bottom. Add
  vertical padding to that scroll view if it bothers you.
- **RTL / Arabic**: `flutter_localizations` is wired; layouts use logical
  directional widgets, so `ar` mirrors automatically. Sanity-check new custom
  paints / `Positioned` for RTL.
- **No new dependencies** without a reason — the app is deliberately lean
  (`http`, `table_calendar`, `flutter_map`, `uuid`, `url_launcher`, `intl`).

## What was NOT touched

Business logic, `AppState`, `ApiService`, models, `demo_data.dart`, l10n keys,
routing, the backend. The rebuild was presentation-only: `app_theme.dart`,
`deco.dart`, and every file in `lib/screens/` + `lib/widgets/`.
