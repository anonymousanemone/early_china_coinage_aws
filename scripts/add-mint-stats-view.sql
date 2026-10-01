-- Aggregating view for the Mint Town overview (/mints, via
-- components/mints/MintsPageContent.tsx). Replaces pulling the entire
-- `finds` table down to the app just to compute per-mint find/coin/site
-- counts in JS. Read by lib/queries.ts's getMintStats and turned into
-- MintStat rows by lib/mint-stats.ts's computeMintStatsFromView.
--
-- Mirrors lib/mint-stats.ts's computeMintStatsFromFinds exactly (verified
-- against live data: identical find/coin/site counts and inscription sets
-- for all 126 mints):
-- - coin_count sums coalesce(quantity_total, quantity_estimated,
--   quantity_min, 0), the same fallback order as lib/quantity.ts's
--   findQuantity().
-- - finds join contexts as an inner join, like getFindsForHeatmap's
--   `contexts!inner(site_code)`.
-- - inscriptions only come from issues that actually have finds (the JS
--   collects them per find, not per catalogued issue).
-- - every mint gets a row, zero-count ones included.
--
-- Name/state/coordinates are deliberately left out: the /mints page already
-- fetches the full `mints` rows for its directory list, and joins on mint_id.
--
-- `security_invoker = true` for the same reason as the views in
-- add-flat-views.sql: runs under the querying role's own RLS rather than the
-- view owner's, so it doesn't silently bypass a future RLS change.
--
-- Run by hand in the Supabase SQL editor -- this repo has no migration
-- runner, scripts/*.sql is the existing convention (see add-flat-views.sql).
create or replace view public.v_mint_stats
with (security_invoker = true) as
select
  m.id as mint_id,
  m.mint_code,
  count(f.id) as find_count,
  coalesce(sum(coalesce(f.quantity_total, f.quantity_estimated, f.quantity_min, 0)), 0) as coin_count,
  count(distinct ctx.site_code) as site_count,
  coalesce(
    array_agg(distinct btrim(ins.inscription_zh)) filter (where f.id is not null and btrim(ins.inscription_zh) <> ''),
    '{}'
  ) as inscriptions
from public.mints m
left join public.coin_issues ci on ci.mint_id = m.id
left join public.inscriptions ins on ins.id = ci.inscription_id
left join (public.finds f join public.contexts ctx on ctx.context_code = f.context_code)
  on f.coin_issues_id = ci.id
group by m.id, m.mint_code;

grant select on public.v_mint_stats to anon, authenticated;
