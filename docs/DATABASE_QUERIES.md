# Database Queries by Page

What each route in `app/` reads from Supabase (Postgres via PostgREST), how much data that pulls, how it's filtered, and how caching/auth affect it.

**Client used for all reads below:** `lib/supabase.ts` — a plain `supabase-js` client with the public **anon key**. Row Level Security grants `SELECT` to `public` on every content table (confirmed via `pg_policies`), so an anonymous visitor and a signed-in admin read exactly the same rows; only `INSERT`/`UPDATE`/`DELETE` are restricted to `authenticated` + `is_admin()`. Auth therefore never filters what a page's *reads* return — it only gates (a) a couple of admin-only lookups noted per page below, and (b) whether edit UI renders.

**Row counts** (live, as of this doc): `sites` 1,830 (`v_coin_map_sites` 1,797 have coordinates) · `contexts` 2,181 · `finds` 6,975 · `coin_issues` / `v_coin_issues_flat` 2,279 · `coin_type_hierarchy` 72 · `sources` 957 · `source_links` 2,336 · `states` 14 · `inscriptions` 346 · `images` 28 · `mints` 126 · `ans_data` 2,947.

**Rendering key:**
- **Static/ISR** — no `cookies()`/`searchParams` read, so Next can pre-render the page and serve it from the Full Route Cache; `revalidate = 86400` (24h) then triggers a background rebuild on next request after expiry.
- **Dynamic (per-request)** — the page calls `isAuthorized()` (→ `createServerSupabaseClient()` → `cookies()`) and/or reads `searchParams`, both of which are "dynamic APIs" that force Next to render on every request. `revalidate = 86400` is still declared on most of these, which sets the default lifetime for the underlying `fetch` calls in Next's **Data Cache** — so the Supabase round-trips themselves can still be cache-hits for up to 24h even though the page shell re-renders each time. It does not mean the page is statically served.

Every list-fetching helper in `lib/queries.ts` pages through PostgREST with `fetchAllPages()` (1,000-row cap per request) rather than truncating, so counts below are full-table unless a query has an explicit filter.

**⚠️ markers below** point to `todo.md` — the running egress-audit Q&A log with the full reasoning, draft SQL, and decisions for each flagged read. This file just says *what's heavy here*; `todo.md` says *why, and what to do about it*. Two systemic bugs recur across several pages' "Rendering" lines rather than being page-specific: (1) `isAuthorized()` reads `cookies()`, which forces dynamic rendering regardless of `revalidate` — hits `/coin-types/[slug]`, `/mints`, `/mints/[mint_code]`, `/sites/[site_code]`, `/sources` (todo.md Q3-response, Q6); (2) reading `searchParams` does the same — hits `/search`, `/visualizations/find-site`, `/visualizations/mint-town`, `/museum-collections` (todo.md Q5a/Q5b), and for three of those four pages there's no server-side filtering happening anyway, so it's a free fix.

---

## `/` (Home) — `app/page.tsx`
- **Queries:** The only query on this route is inside `<HeroBanner>` (`components/home/HeroBanner.tsx`): `getDatabaseStats()` → two `head: true` count-only queries (`v_coin_map_sites`, **1,797** rows counted / `finds`, **6,975** rows counted — neither returns row bodies, just the count) plus one RPC call, `sum_total_quantity_for_map()` (`scripts/add-sum-total-quantity-function.sql`), which sums `total_quantity_for_map` in Postgres and returns a single number — **0 rows** shipped to the app.  plain PostgREST aggregate selects (`.select('col.sum()')`) aren't available on this project (`db-aggregates-enabled` is off — confirmed live, returns `PGRST123`), so the sum moved into a Postgres function instead.
- **Used for:** the hero banner's live database-size stats.
- **Rendering:** Static/ISR, `revalidate = 86400`. No auth check, no searchParams — genuinely pre-rendered and CDN-cacheable. The `revalidate` export is kept specifically for `getDatabaseStats()`'s Data Cache lifetime.
- **Auth impact:** None.
- **Note:** `sum_total_quantity_for_map()` (`scripts/add-sum-total-quantity-function.sql`) is live on the DB and verified callable via the anon key over PostgREST (returns `698713`, matching the prior full-row-sum result).

## `/about` — `app/about/page.tsx`

- **Queries:** None. Fully static content (team bios, links, a static schema image).
- **Auth impact:** Renders `<AuthStatus>`, a client component that calls `/api/auth/me` (see below) — not a page-level DB call.

## `/search` — `app/search/page.tsx`

- **Queries:**
  - `getAllSites()` → `v_coin_map_sites` (all 1,797 geocoded rows, ordered by `site_name_zh`) **+** `getPrecisionSupplementSites()` (two extra `sites` queries: `ilike site_name_zh '%不明单位%'` and `eq county_zh '不明'`, ~39 county-level rows) **+** `attachSiteDetails()` (all `sites` rows for `description_zh/en` + joined `periods`).
  - `getCoinIssues()` → `v_coin_issues_flat`, all 2,279 rows (used to build EN lookup tables and to translate an English search term to its Chinese equivalent before filtering).
  - `getFindsForSiteCodes(pageResults)` → two-step `contexts` (by `site_code`) then `finds` (by `context_code`), scoped **only to the 20 sites on the current results page** — explicitly written this way (see code comment) to avoid a full `finds` scan on every search.
- **Filtering:** All text search, facet filtering (mint/coin type/inscription/state/region/period/site type/quantity/single-find), sorting, and pagination happen **in memory in the page component**, not in SQL — `filterSitesByQuery()` and `lib/search-filters.ts`. The DB queries always pull the full site+coin-issue catalog; only the per-card pie-chart data (`getFindsForSiteCodes`) is scoped to the visible page.
- **Rendering:** Declared Static/ISR (`revalidate = 86400`, `maxDuration = 60`), but the page reads `searchParams` for every filter/sort/page value, so Next renders it dynamically per unique query string. The underlying Supabase fetches can still hit Next's Data Cache for up to 24h.
- **Auth impact:** None on data returned.
- **Notes:** This is the most expensive page per request — it's the only one that combines the full sites catalog, the full coin-issues catalog, and (for unfiltered/early pages) can still touch `contexts`/`finds`. A code comment notes a prior version that re-fetched both catalogs internally could push past Vercel's function timeout; the current version fetches each once and shares it.
- **⚠️ todo.md Q5a/Q5b/Q5d:** the *only* page that legitimately needs the full sites+coin-issues catalog server-side, since it does real filter/sort/paginate in-memory. DB-side pagination (`LIMIT`/`OFFSET`) was considered and rejected here specifically — see Q5b's response — because the filter logic (free-text across CSV columns, EN→ZH term translation) would have to be duplicated in SQL/RPC, and the actual row-count win is smaller than it looks (~1,050 rows total today, not thousands). **Recommended fix instead:** point the base fetch at a local JSON snapshot (Q5d) so this read costs zero Supabase egress regardless of traffic — still needs an explicit staleness answer (bifurcate on `authorized`, a Supabase webhook, or nightly cron) before starting.

## `/coin-types` — `app/coin-types/page.tsx`

- **Queries:** `getCoinIssues()` (2,279 rows) + `getCoinTypeHierarchy()` (72 rows) + `getFindsForHeatmap()` → `finds` joined to `contexts!inner(site_code)`, all 6,975 rows.
- **Used for:** building the full typology tree and per-type find/site counts shown on each type's card; no per-request filtering (search/filter on this list happens client-side in `CoinTypeListClient`).
- **Rendering:** Static/ISR, `revalidate = 86400`. No auth check or searchParams — pre-rendered.
- **Auth impact:** None.

## `/coin-types/[slug]` — `app/coin-types/[slug]/page.tsx`

- **Queries:**
  - `generateMetadata`: `getCoinTypeHierarchy()` alone (72 rows) — cheap, just to resolve the slug's label for the `<title>`.
  - Page body: `getCoinIssues()` (2,279) + `getCoinTypeHierarchy()` (72) + `getFindsForHeatmap()` (6,975, joined to `contexts`) + `getFindSpotsMapSites()` (`v_coin_map_sites` 1,797 + precision-supplement `sites` queries, merged).
  - `getMints()` (all 126, joined to `states`) — needed for every visitor to resolve mint-name → `/mints/[code]` links, not just admins.
  - **Admin-only:** if `isAuthorized()`, additionally `getStates()` (14 rows) and `getInscriptions()` (346 rows) to populate the coin-issue-editing comboboxes. Skipped entirely for anonymous visitors.
- **Filtering:** `coin_type_code`/hierarchy matching for "related finds" and "matched coin issues" is done in memory against the already-fetched hierarchy tree (`node.matchedHierarchyIds`), not via a SQL `WHERE`.
- **Rendering:** Dynamic per-request — the code comment explains `generateStaticParams` was deliberately removed because `isAuthorized()` reads cookies, a dynamic API that can't resolve at build time. `revalidate = 86400` still bounds the underlying fetches' Data Cache lifetime.
- **Auth impact:** Adds 2 extra queries (`states`, `inscriptions`) for admins only; also gates whether the edit comboboxes/description editor render. Forces the whole route to be request-dynamic regardless of visitor auth state, since the auth check itself must run per request.
- **⚠️ todo.md Q4, Q5a, Q6 — flagged as the worst offender site-wide.** Full `finds` (6,975 rows) and full `getFindSpotsMapSites()` are scanned and then almost entirely discarded to render *one* type's stats — and unlike `/search`'s cost, this isn't gated behind a user action; every plain visit to every coin-type page re-pays it in full. Two scoped-query fixes are drafted but **not yet wired up**: `getFindsByIssueIds(issueIds)` in place of `getFindsForHeatmap()` (Q4, code included in that section), and a proposed `getMapSitesByCodes(siteCodes)` in place of `getFindSpotsMapSites()` for the `relatedSites` table (Q6). Q6 also notes the `isAuthorized()`-forces-dynamic bug on this page is arguably *more* impactful than either query-scoping fix, since it multiplies every fetch above by "once per visit" instead of "once per 24h."

## `/mints` — `app/mints/page.tsx`

- **Queries:** `getMints()` (126, + joined `states`) + `getFindsForHeatmap()` (6,975) + `getCoinIssues()` (2,279) + `getImages()` (`images`, 28 rows, joined to `sources`).
- **Used for:** the mint-town overview map preview and the full searchable mint directory list (stats, coin-type tags, issue counts, completeness score) — all computed in memory from the four fetched sets; no per-request DB filtering (search/sort is client-side).
- **Rendering:** Dynamic per-request (calls `isAuthorized()` to gate the "Add mint" UI). `revalidate = 86400` on the Data Cache layer.
- **Auth impact:** Only changes whether `<AddMintSection>` renders its authenticated form; no extra queries.
- **⚠️ todo.md Q1/Q3:** `getFindsForHeatmap()` + `getCoinIssues()` fetched in full just to compute ~40 mint-level aggregate rows (stat badges, issue-count sort, coin-type tags). An aggregating view, `v_mint_stats` (drafted: `scripts/add-mint-stats-view.sql`, reviewed and **approved**), would replace the `finds` fetch with one small `GROUP BY`-aggregated query — **not yet run against the live DB or wired into this page** (see Q2's step-by-step plan: run → spot-check 2-3 mints → swap the app code).

## `/mints/[mint_code]` — `app/mints/[mint_code]/page.tsx`

- **Queries:**
  - `resolveMintPage()` (wrapped in React `cache()` so `generateMetadata` and the page body share one fetch): `getMints()` (126) + `getImages()` (28).
  - `getMintFindspotsData(mint.id)`: one `v_coin_issues_flat` query `eq mint_id` (typically a handful to a few dozen rows for a given mint), then — only if that mint has catalogued issues — `finds` `in coin_issues_id` (chunked at 150 ids/request), then `contexts` `in context_code`, then `v_coin_map_sites` `in site_code`. Returns 0 rows early if the mint has no catalogued coin issues.
  - `getCoinIssues()` (2,279) + `getCoinTypeHierarchy()` (72) — to resolve type labels back to their `/coin-types` slug.
  - `getSourceLinksForMint(mint_code)` → `source_links` `eq target_type='mint' eq target_code`, then `getSources(...)` scoped to just those codes + `resolveSourceLinkTargets(...)`.
- **Filtering:** All scoped to the one mint (`mint_id`/`mint_code` equality filters), except the two full-catalog fetches (`getCoinIssues`, `getCoinTypeHierarchy`) used purely for label/slug resolution.
- **Rendering:** Dynamic per-request (`isAuthorized()` for the dev-only "Database Record" panel). `revalidate = 86400` on fetch caching.
- **Auth impact:** Gates only the raw-row debug panel; no extra queries.
- **⚠️ todo.md Q6:** `resolveMintPage()` fetches all 126 `mints` + all 28 `images` just to find one mint by code via a JS `.find()` — `getMintFindspotsData()` right below it already shows the correct scoped pattern (`.eq mint_id` → `.in coin_issues_id`, never touches full `finds`). Proposed fix: a `getMintByCode(mintCode)` mirroring `getSite()`'s `.eq(...).maybeSingle()` exactly — drafted in Q6 (code included there), not applied. Low byte-savings since `mints`/`images` are small tables, but flagged as an easy, correct fix for consistency.

## `/museum-collections` — `app/museum-collections/page.tsx`

- **Queries:** `getAnsSpecimens()` → `v_ans_flat` (all 2,947 rows) + `getCoinTypeHierarchy()` (72) + `getMintInfos()` (→ `getMints()`, 126).
- **Used for:** the ANS mint-town map visualization and its accession-number search, entirely client-rendered from this one payload.
- **Rendering:** Static/ISR, `revalidate = 86400`. No auth check; `searchParams` (`view`, `types`) are read but only to set initial client-side view state passed as props — this doesn't opt the page out of static rendering the way `cookies()` does, though in practice any `searchParams` usage does make Next treat the segment as dynamic. Net effect: same as other `searchParams`-only pages — dynamic shell, cached Data-Cache fetches underneath.
- **Auth impact:** None.
- **Notes:** `ans_data` (2,947 rows) is the single largest table read on the site.
- **⚠️ todo.md Q5-response:** full unfiltered `ans_data` shipped to the client for entirely in-browser aggregation and accession-number search — zero server-side narrowing. `v_ans_flat` (`scripts/add-ans-flat-view.sql`, applied) removes the client-side join code — including the `getCoinIssues()` fetch this page used to make just to resolve inscription bilingual labels — but **does not by itself reduce row count/egress**. The actual egress fix needs a scoped fetch or the snapshot approach (Q5d), on top of (or instead of) the view. Independently, this page also pays the `searchParams`-breaks-caching tax below for zero server-filtering benefit.

## `/sites/[site_code]` — `app/sites/[site_code]/page.tsx`

- **Queries (all sequential, not `Promise.all`'d, except where noted):**
  - `generateMetadata`: `getSite(site_code)` — wrapped in React `cache()`, `sites` `eq site_code .maybeSingle()` joined to `periods`, so the page body's own `getSite()` call reuses this result instead of re-querying.
  - `isAuthorized()`.
  - `getSiteMapSummary(site_code)` → `v_coin_map_sites` `eq site_code .maybeSingle()`.
  - `getSiteContexts(site_code)` → `contexts` `eq site_code`, joined to `periods` (typically 1–5 rows per site; 2,181 rows total across all sites).
  - `getSiteFinds(contextCodes)` → `finds` `in context_code`, joined to the full `coin_issues` embed (`mints`/`states`/`inscriptions`/`coin_type_hierarchy`), plus a conditional `getCoinTypeHierarchy()` call if any returned find's coin issue lacks a `coin_type_hierarchy_id`.
  - `getMintInfos()` → all 126 mints (for mint-name → `/mints/[code]` links).
  - **Admin-only:** `getCoinIssues()` (2,279 rows) — "only needed to populate the find-editing combobox, so skip the fetch in prod" for anonymous visitors; also `getCoinTypeHierarchy()` unconditionally (72 rows) for the "Coin Types" label links.
  - `getSourceLinksForSite(site_code, contextCodes, findCodes)` → three separate `source_links` queries (`target_type` = site/context/find), findCodes chunked at 150/request; then `getSources(...)` scoped to just the codes returned + `resolveSourceLinkTargets(...)`.
- **Filtering:** Everything is scoped by `site_code`/`context_code`/`find_code` equality or `IN` filters except the two full-catalog admin/label-resolution fetches noted above.
- **Rendering:** Dynamic per-request (`isAuthorized()`). `revalidate = 86400` on the Data Cache layer.
- **Auth impact:** Adds one extra full-table query (`getCoinIssues()`, 2,279 rows) for admins to support inline editing; also renders the raw "Site Record (dev only)" panel.
- **Notes:** This page issues the most separate round-trips of any route (up to ~9 sequential queries plus 3 more for source links) because a site's finds, contexts, and sources are each resolved in their own step; none of them are large individually (a site rarely has more than a few dozen finds), but the sequential (non-parallel) awaits mean latency stacks rather than overlapping.
- **⚠️ todo.md Q6:** already close to ideal on row-scoping — every finds/contexts/sources query here is properly `.eq`/`.in`-scoped. The one full-table read (`getCoinIssues()`, admin-only) isn't a "fetch one row instead" candidate despite the pattern elsewhere on this page — it backs an edit dropdown that needs every option to choose from, per Q5's response to that exact question. **The real lever on this page is the `isAuthorized()`-forces-dynamic caching bug**, not further query-scoping (Q6 summary ranks this bug above any row-scoping fix for all three `isAuthorized()`-gated detail pages).

## `/sources` — `app/sources/page.tsx`

- **Queries:** `getAllSources()` (`sources`, all 957 rows) + `getAllSourceLinks()` (`source_links`, all 2,336 rows) + `resolveSourceLinkTargets(links)` (resolves each link's target label — see below) + `isAuthorized()`.
- **Used for:** the full searchable/filterable source bibliography; search and filtering are client-side (`SourcesListClient`) over this one fetched set.
- **Rendering:** Dynamic per-request (`isAuthorized()` gates admin edit controls). `revalidate = 86400` on fetch caching.
- **Auth impact:** No extra queries; gates whether inline add/edit controls render.
- **Notes:** `resolveSourceLinkTargets` likely issues additional lookups per distinct target table to turn each link's `target_code` into a display label — with 2,336 links this is the main cost driver on this page (see `lib/admin/resolve-source-link-target.ts` if optimizing further).
- **⚠️ Not yet covered in `todo.md`** — no aggregation/scoping candidate has been identified for this page's full `sources`+`source_links` reads. Worth its own pass, starting with profiling `resolveSourceLinkTargets`'s actual query count. It does inherit the `isAuthorized()`-forces-dynamic caching bug shared with `/mints`, `/mints/[mint_code]`, `/sites/[site_code]`, `/coin-types/[slug]`.

## `/visualizations` — `app/visualizations/page.tsx`

- **Queries:** None. Pure `redirect()` to one of two tabs, chosen randomly server-side.
- **Rendering:** `export const dynamic = 'force-dynamic'` — explicitly opted out of caching so the coin flip re-rolls every request.

## `/visualizations/find-site` — `app/visualizations/find-site/page.tsx`

- **Queries:** `getFindSpotsMapSites()` (`v_coin_map_sites` 1,797 + precision supplements from `sites`) + `getCoinIssues()` (2,279) + `getCoinTypeHierarchy()` (72) + `getFindsForHeatmap()` (6,975, joined `contexts`) + `getMintInfos()` (126).
- **Filtering:** A `precision` searchParam filters the already-fetched site list in memory (`siteMatchesPrecisionFilter`); all other map filtering (coin type, mint, etc.) happens client-side in the visualization component.
- **Rendering:** Declared Static/ISR (`revalidate = 86400`) but reads `searchParams` (`precision`, `mode`, `view`, `mints`, `types`), so it renders dynamically per unique query string; underlying fetches still cache for 24h.
- **Auth impact:** None.
- **Notes:** This is the full unfiltered find-spots dataset (every georeferenced site + every find) shipped to the client for interactive filtering — the heaviest payload of the three map-visualization pages alongside `/museum-collections`.
- **⚠️ todo.md Q5a/Q5b:** confirmed **zero real server-side filtering** happens here beyond `precision` — `mode`/`mints`/`types`/`view` are decoded and passed straight through as props, filtered entirely client-side in `MapVisualization.tsx`. That means the `searchParams` read is breaking `revalidate=86400` for almost no benefit. Removing the server-side `searchParams` dependency (decode client-side instead) is flagged as a **free fix with no behavior change**.

## `/visualizations/mint-town` — `app/visualizations/mint-town/page.tsx`

- **Queries:** `getCoinIssues()` (2,279) + `getCoinTypeHierarchy()` (72) + `getFindsForHeatmap()` (6,975) + `getMintInfos()` (126).
- **Rendering:** Static/ISR (`revalidate = 86400`); only reads `view`/`types` searchParams for initial client state.
- **Auth impact:** None.
- **⚠️ todo.md Q5a/Q5b:** same pattern as `/visualizations/find-site` — **zero server-side filtering** (`view`/`types` go straight to `parseCommonDeeplinkParams` as props). Same free fix: drop the server-side `searchParams` read.

## `/login` — `app/login/page.tsx`

- **Queries:** None directly. Submitting the form calls the `signInWithPassword` Server Action (`lib/auth/actions.ts`), which calls Supabase **Auth** (`auth.signInWithPassword`) — not a table read/write.
- **Rendering:** Static shell.

## `/auth/callback` (Route Handler) — `app/auth/callback/route.ts`

- **Queries:** None on app tables — exchanges an OAuth code via Supabase Auth (`auth.exchangeCodeForSession`), then redirects.

## `/api/auth/me` (Route Handler) — `app/api/auth/me/route.ts`

- **Queries:** None on app tables — calls `getCurrentUserEmail()` → Supabase Auth `getClaims()` to read the JWT. Fetched client-side by `SiteHeader`/`AuthStatus` specifically so the rest of a page doesn't have to become request-dynamic just to show login state.
- **Rendering:** Always dynamic (per-request auth check by design), but isolated to this one small endpoint.

---

## Cross-cutting notes

- **No page issues raw SQL** — every read goes through PostgREST via `supabase-js`, so "queries" above are `.from(table).select(...)` calls with `.eq/.in/.ilike/.order/.range()`, not hand-written SQL.
- **Two Postgres views do the heavy joining that pages would otherwise do client-side:** `v_coin_map_sites` (site + aggregated find/type/inscription/mint CSVs, keeping `/search`, `/coin-types`, the map visualizations, and site detail from having to join `sites`→`contexts`→`finds`→`coin_issues` themselves) and `v_coin_issues_flat` (coin_issues pre-joined to mints/states/inscriptions/hierarchy with major/minor type already derived in SQL, per the comment in `getCoinIssues()`).
- **The "legacy hierarchy" fallback** (`applyLegacyHierarchy` in `lib/queries.ts`) adds a conditional extra query on `getSiteFinds`, `getCoinIssues`, and `fillMissingMapSiteTypes` whenever a row's `coin_type_hierarchy_id` is null — it resolves the type from a `legacy_type` free-text column instead. This is a migration-transition path, not a steady-state cost, and disappears once every `coin_issues` row has a hierarchy id.
- **Two resilience fallbacks degrade rather than fail:** `attachSiteDetails()` (used by `/search`'s `getAllSites`) swallows errors and returns sites with null period/description rather than 500ing if the `periods` join breaks; `getFindsForSiteCodes()` (per-card pies on `/search`) does the same, logging and returning `[]` rather than taking down the results list.
- **Auth's actual effect on data is narrow:** it only ever adds `getStates()`/`getInscriptions()` (on `/coin-types/[slug]`) or `getCoinIssues()` (on `/sites/[site_code]`) for admin edit UI, and toggles a handful of dev-only debug panels. It never changes which rows a query returns, since RLS grants public `SELECT` on every content table. **Its indirect effect is the opposite of narrow, though:** `isAuthorized()` reading `cookies()` is a confirmed caching bug on 5 pages (see the ⚠️ markers above), and per `todo.md` Q6's summary it's ranked as more impactful than any individual row-scoping fix, since it multiplies every other fix on those pages by "once per visit" instead of "once per 24h."

---

## Egress backlog (see `todo.md` for full detail)

Ranked, per `todo.md`'s "Egress Contributor Summary" and Q6's closing summary:

1. Un-break caching on `/visualizations/mint-town`, `/visualizations/find-site`, `/museum-collections` — free fix, no server-side filtering to preserve (Q5b).
2. Move `isAuthorized()` off the server render path for `/coin-types/[slug]`, `/mints`, `/mints/[mint_code]`, `/sites/[site_code]`, `/sources` (Q3-response).
3. `getFindsByIssueIds()` + `getMapSitesByCodes()` for `/coin-types/[slug]` (Q4, Q6) — highest-value row-scoping fix.
4. Run `v_mint_stats` (drafted, approved) and wire into `/mints` (Q1/Q2).
5. `getMintByCode()` for `/mints/[mint_code]` (Q6) — small but easy.
6. ✅ **Applied:** `v_ans_flat` (`getAnsSpecimens()` now reads it directly). Still open: decide whether `/museum-collections` needs an actual scoped fetch/snapshot on top of it (Q5d) — the view only removed the client-side join, not the full-table egress.
7. Dedupe `getAllSites()`'s two independent full `sites` scans (Q5a).
8. Big decision, not a patch: CSV/JSON snapshot architecture for `/search` — needs a staleness answer first (Q5d).
9. Commit `CREATE VIEW` source for `v_coin_map_sites`/`v_coin_finds` (only live in the Supabase SQL editor today) and decide whether to keep or drop the confirmed-unused `v_coin_finds` (Q2, Q7).
