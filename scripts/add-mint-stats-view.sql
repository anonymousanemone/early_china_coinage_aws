-- Aggregating view for the Mint Town overview (app/mints/page.tsx) and any
-- other unfiltered "one row per mint" consumer. Replaces pulling the entire
-- `finds` table down to the app just to compute per-mint find/coin/site
-- counts in JS (see lib/mint-stats.ts's computeMintStatsFromFinds, which
-- this view's find_count/coin_count/site_count columns are meant to mirror
-- exactly -- coin_count sums coalesce(quantity_total, quantity_estimated,
-- quantity_min, 0), the same fallback order as lib/quantity.ts's
-- findQuantity()).
--
-- `security_invoker = true` for the same reason as the views in
-- add-flat-views.sql: runs under the querying role's own RLS rather than the
-- view owner's, so it doesn't silently bypass a future RLS change.
--
-- Run by hand in the Supabase SQL editor -- this repo has no migration
-- runner, scripts/*.sql is the existing convention (see add-flat-views.sql).
--
-- NOT YET WIRED UP to any page -- this is a draft for review. Before running:
-- 1. Check it against a few known mints' numbers in the current app (the
--    /mints page's stat cards) to confirm find_count/coin_count/site_count
--    match exactly.
-- 2. Decide whether inscriptions/type-tag columns are worth adding here too
--    (MintsPage's typesByMint/issuesByMint still need a separate
--    getCoinIssues() call as drafted -- see lib/mint-directory.ts's
--    buildMintTypeLabels for the exact label-dedup rule to port if folding
--    those in later).
create or replace view public.v_mint_stats
with (security_invoker = true) as
select
  m.mint_code,
  m.name_zh as mint_zh,
  m.name_en as mint_en,
  m.latitude as lat,
  m.longitude as lng,
  count(distinct f.find_code) as find_count,
  coalesce(sum(coalesce(f.quantity_total, f.quantity_estimated, f.quantity_min, 0)), 0) as coin_count,
  count(distinct ctx.site_code) as site_count,
  array_remove(array_agg(distinct ci.inscription), null) as inscriptions
from public.mints m
left join public.coin_issues ci on ci.mint_id = m.id
left join public.finds f on f.coin_issues_id = ci.id
left join public.contexts ctx on ctx.context_code = f.context_code
group by m.mint_code, m.name_zh, m.name_en, m.latitude, m.longitude;

grant select on public.v_mint_stats to anon, authenticated;
