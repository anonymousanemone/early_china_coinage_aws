import { FullViewportMapShell } from '@/components/visualizations/FullViewportMapShell'
import { AnsMintTownVisualization } from '@/components/visualizations/MapVisualization'
import { getAnsSpecimens } from '@/lib/ans-museum-data'
import { getMintInfos } from '@/lib/queries'
import { parseCommonDeeplinkParams } from '@/lib/visualization-deeplink'

type PageProps = {
  searchParams: Promise<{ view?: string; types?: string }>
}

export const metadata = {
  title: 'Museum Collections | Early Chinese Coin Finds',
  description: 'Mint-town distribution of ANS museum specimens, searchable by accession number.',
}

export const revalidate = 86400

export default async function MuseumCollectionsPage({ searchParams }: PageProps) {
  const { view, types } = await searchParams

  const [specimens, mints] = await Promise.all([getAnsSpecimens(), getMintInfos()])

  return (
    <FullViewportMapShell>
      <AnsMintTownVisualization specimens={specimens} mints={mints} {...parseCommonDeeplinkParams(view, types)} />
    </FullViewportMapShell>
  )
}
