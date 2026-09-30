import { SiteDetailContent } from '@/components/site/SiteDetailContent'
import { getSite } from '@/lib/queries'

type PageProps = {
  params: Promise<{ site_code: string }>
}

// Public view — never calls isAuthorized()/cookies(), so this stays
// ISR-eligible (once a slug has been requested at least once — see below).
// Editing lives at /sites/[site_code]/edit instead of behind an inline
// authorized check here (see that route for why).
//
// Deliberately NO generateStaticParams here, unlike /coin-types/[type_code] and
// /mints/[mint_code]: this table has ~1,830 rows, and each site's own
// content function already issues up to ~9 sequential Supabase queries
// (contexts, finds, sources, etc.) — prerendering all of them would turn
// every build/24h-revalidation into ~16,000+ sequential DB round trips.
// Without generateStaticParams, a requested site still renders per-request
// (no Full Route Cache), same runtime cost as before minus the auth-check
// overhead and the anonymous-visitor coinIssues fetch this split also
// removes. If you want full ISR caching here too, it needs a deliberate
// call given that build-time cost — ask before adding it wholesale; a
// partial generateStaticParams (e.g. only sites with find records) is a
// middle ground worth considering instead of all 1,830.

export const revalidate = 86400

export async function generateMetadata({ params }: PageProps) {
  const { site_code } = await params
  const site = await getSite(site_code)
  if (!site) return { title: 'Site not found / 未找到该遗址' }
  return {
    title: `${site.site_name_zh ?? site_code} | Early Chinese Coin Finds`,
    description: site.description_en ?? site.description_zh ?? undefined,
  }
}

export default async function SitePage({ params }: PageProps) {
  const { site_code } = await params
  return <SiteDetailContent site_code={site_code} authorized={false} />
}
