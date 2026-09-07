#!/usr/bin/env bash
# Regenerate frontend/api-fixtures/ from a locally running Django backend.
# These fixtures are what netlify/functions/api.mjs replays as the demo API.
#
#   cd backend
#   rm -f db.sqlite3
#   python manage.py migrate
#   for c in seed_users seed_localities seed_products seed_visits backfill_targets; do python manage.py $c; done
#   DJANGO_DEBUG=true DEMO_MOCK=true python manage.py runserver 127.0.0.1:8000 --noreload &
#   cd ../frontend && bash tools/capture_fixtures.sh
set -euo pipefail

B=${API:-http://127.0.0.1:8000/api}
OUT=api-fixtures
mkdir -p "$OUT/doctor-history"

tok() { curl -s -m 10 -X POST "$B/auth/login/" -H 'Content-Type: application/json' \
          -d "{\"username\":\"$1\",\"password\":\"$2\"}" | python -c "import sys,json;print(json.load(sys.stdin)['token'])"; }
TA=$(tok admin admin123)
TM=$(tok medrep1 med123)

get() { curl -s -m 20 -H "Authorization: Token $1" "$B$2"; }
save() { python -c "import sys,json;json.dump(json.load(sys.stdin),open('$1','w'),ensure_ascii=False,indent=1)"; echo "  $1"; }

get "$TA" "/visits/?all=1"                 | save "$OUT/visits.json"
get "$TA" "/doctors/?all=1"                | save "$OUT/doctors.json"
get "$TA" "/pharmacies/?all=1"             | save "$OUT/pharmacies.json"
get "$TA" "/products/"                     | save "$OUT/products.json"
get "$TA" "/wilayas/"                      | save "$OUT/wilayas.json"
get "$TA" "/localities/"                   | save "$OUT/localities.json"
get "$TA" "/dashboard/manager/"            | save "$OUT/dashboard-manager.json"
get "$TA" "/dashboard/leaderboard/"        | save "$OUT/dashboard-leaderboard.json"
get "$TA" "/alerts/"                       | save "$OUT/alerts.json"
get "$TA" "/analytics/map/"                | save "$OUT/analytics-map.json"
get "$TA" "/admin/kpis/"                   | save "$OUT/admin-kpis.json"
get "$TA" "/representatives/"              | save "$OUT/representatives.json"
get "$TM" "/dashboard/delegate/"           | save "$OUT/dashboard-delegate.json"
get "$TM" "/dashboard/delegate/analytics/" | save "$OUT/dashboard-delegate-analytics.json"
for id in $(python -c "import json;print(*[d['id'] for d in json.load(open('$OUT/doctors.json'))])"); do
  get "$TA" "/doctors/$id/history/" | save "$OUT/doctor-history/$id.json"
done
echo "done — if doctor ids changed, update the import list in netlify/functions/api.mjs"
