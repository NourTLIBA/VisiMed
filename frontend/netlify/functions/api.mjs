// VisiMed demo API — a stand-in for the Django backend so every screen works
// without hosting a server. GET endpoints replay JSON captured from the real
// backend (../../api-fixtures/, see tools/capture_fixtures.sh). Login accepts
// the demo accounts; writes are acknowledged but not persisted.
//
// Point the app at the real backend by setting VISIMED_API_URL — nothing here
// needs to change.

import visits from "../../api-fixtures/visits.json";
import doctors from "../../api-fixtures/doctors.json";
import pharmacies from "../../api-fixtures/pharmacies.json";
import products from "../../api-fixtures/products.json";
import wilayas from "../../api-fixtures/wilayas.json";
import localities from "../../api-fixtures/localities.json";
import dashboardManager from "../../api-fixtures/dashboard-manager.json";
import dashboardDelegate from "../../api-fixtures/dashboard-delegate.json";
import dashboardDelegateAnalytics from "../../api-fixtures/dashboard-delegate-analytics.json";
import dashboardLeaderboard from "../../api-fixtures/dashboard-leaderboard.json";
import alerts from "../../api-fixtures/alerts.json";
import analyticsMap from "../../api-fixtures/analytics-map.json";
import adminKpis from "../../api-fixtures/admin-kpis.json";
import representatives from "../../api-fixtures/representatives.json";

import h1 from "../../api-fixtures/doctor-history/1.json";
import h2 from "../../api-fixtures/doctor-history/2.json";
import h3 from "../../api-fixtures/doctor-history/3.json";
import h4 from "../../api-fixtures/doctor-history/4.json";
import h5 from "../../api-fixtures/doctor-history/5.json";
import h6 from "../../api-fixtures/doctor-history/6.json";
import h7 from "../../api-fixtures/doctor-history/7.json";
import h8 from "../../api-fixtures/doctor-history/8.json";

// Netlify Functions v2: register this handler for every /api/* request.
export const config = { path: ["/api", "/api/*"] };

const HISTORY = { 1: h1, 2: h2, 3: h3, 4: h4, 5: h5, 6: h6, 7: h7, 8: h8 };

const USERS = {
  admin: { id: 1, username: "admin", email: "admin@visimed.dz", first_name: "", last_name: "", role: "admin", assigned_regions: "", territory: null, territory_name: null, telephone: "" },
  manager1: { id: 2, username: "manager1", email: "manager1@visimed.dz", first_name: "", last_name: "", role: "manager", assigned_regions: "", territory: null, territory_name: null, telephone: "" },
  medrep1: { id: 3, username: "medrep1", email: "medrep1@visimed.dz", first_name: "", last_name: "", role: "med_rep", assigned_regions: "Alger,Blida", territory: null, territory_name: null, telephone: "" },
  pharmrep1: { id: 4, username: "pharmrep1", email: "pharmrep1@visimed.dz", first_name: "", last_name: "", role: "pharma_rep", assigned_regions: "Oran,Mostaganem", territory: null, territory_name: null, telephone: "" },
};

const CORS = {
  "access-control-allow-origin": "*",
  "access-control-allow-methods": "GET,POST,PATCH,PUT,DELETE,OPTIONS",
  "access-control-allow-headers": "authorization,content-type,accept,bypass-tunnel-reminder",
};

const json = (body, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json", ...CORS },
  });

function hex(n = 32) {
  let s = "";
  while (s.length < n) s += Math.random().toString(16).slice(2);
  return s.slice(0, n);
}

export default async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: CORS });

  // Path arrives as either /api/... (200 rewrite) or /.netlify/functions/api/...
  let path = new URL(req.url).pathname
    .replace(/^\/\.netlify\/functions\/api/, "")
    .replace(/^\/api/, "");
  if (!path.startsWith("/")) path = "/" + path;
  const m = req.method;

  // ── auth ────────────────────────────────────────────────────────────────
  if (path === "/auth/login/" && m === "POST") {
    let body = {};
    try { body = await req.json(); } catch { /* ignore */ }
    const u = USERS[String(body.username || "").trim().toLowerCase()];
    if (!u) return json({ non_field_errors: ["Invalid credentials. Try one of the demo accounts."] }, 400);
    return json({ token: "demo-" + hex(16), user: u });
  }
  if (path === "/auth/logout/" && m === "POST") return new Response(null, { status: 204, headers: CORS });
  if (path === "/health/") return json({ status: "ok" });

  // ── writes: acknowledge, don't persist ─────────────────────────────────
  if (path === "/visits/" && m === "POST") {
    let body = {};
    try { body = await req.json(); } catch { /* ignore */ }
    return json({
      ...body,
      id: hex(32),
      created_at: new Date().toISOString(),
      rep: 3,
      rep_username: "medrep1",
      presented_products: [],
      prescriptions: [],
    }, 201);
  }
  if (path.startsWith("/representatives/") && (m === "POST" || m === "PATCH" || m === "PUT")) {
    let body = {};
    try { body = await req.json(); } catch { /* ignore */ }
    return json({ id: Math.floor(Math.random() * 1e6), is_active: true, ...body }, m === "POST" ? 201 : 200);
  }
  if (path.startsWith("/representatives/") && m === "DELETE") return new Response(null, { status: 204, headers: CORS });
  if (path.match(/^\/representatives\/\d+\/reset_password\/$/) && m === "POST")
    return json({ status: "password set" });

  // ── reads ──────────────────────────────────────────────────────────────
  if (m === "GET" || m === "HEAD") {
    if (path === "/visits/") return json(visits);
    if (path === "/doctors/") return json(doctors);
    if (path === "/pharmacies/") return json(pharmacies);
    if (path === "/products/") return json(products);
    if (path === "/wilayas/") return json(wilayas);
    if (path === "/representatives/") return json(representatives);
    if (path === "/localities/") {
      const w = new URL(req.url).searchParams.get("wilaya");
      return json(w ? localities.filter((l) => (l.nom_wilaya || "").toLowerCase() === w.toLowerCase()) : localities);
    }
    if (path === "/dashboard/manager/") return json(dashboardManager);
    if (path === "/dashboard/delegate/") return json(dashboardDelegate);
    if (path === "/dashboard/delegate/analytics/") return json(dashboardDelegateAnalytics);
    if (path === "/dashboard/leaderboard/") return json(dashboardLeaderboard);
    if (path === "/alerts/") return json(alerts);
    if (path === "/analytics/map/") return json(analyticsMap);
    if (path === "/admin/kpis/") return json(adminKpis);

    const dh = path.match(/^\/doctors\/(\d+)\/history\/$/);
    if (dh) return json(HISTORY[dh[1]] || HISTORY[1]);

    if (path.match(/^\/exports\/(csv|xlsx|pdf)\/$/)) {
      return new Response("VisiMed demo export — connect the real backend for full reports.\n", {
        status: 200,
        headers: { "content-type": "text/csv", "content-disposition": 'attachment; filename="visimed_demo.csv"', ...CORS },
      });
    }
  }

  return json({ detail: "Not found (demo API). Path: " + path }, 404);
};
