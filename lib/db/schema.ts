import {
  bigint,
  boolean,
  doublePrecision,
  integer,
  jsonb,
  numeric,
  pgTable,
  pgView,
  text,
  timestamp,
  uuid,
} from 'drizzle-orm/pg-core'
import type { MintTypeLabel } from '@/lib/mint-directory'

/**
 * Hand-written to mirror the live Supabase schema (scripts/schemas.sql plus
 * the add-*.sql migrations) — the read side of lib/queries.ts only, not a
 * migration source. Property names are kept snake_case, identical to the
 * column names, so `db.select().from(t)` rows already match the shapes in
 * lib/types.ts that the old supabase-js `select('*')` calls returned.
 *
 * Types are pinned to what PostgREST used to return over JSON: numeric/int8
 * columns as JS numbers (postgres-js would otherwise hand back strings) and
 * timestamptz as strings. Swap pg-core for mysql-core here when migrating.
 */

const createdAt = (nullable = true) => {
  const col = timestamp('created_at', { withTimezone: true, mode: 'string' })
  return nullable ? col : col.notNull()
}

export const periods = pgTable('periods', {
  id: uuid('id').primaryKey(),
  period_zh: text('period_zh').notNull(),
  period_en: text('period_en').notNull(),
  created_at: createdAt(false),
})

export const sites = pgTable('sites', {
  id: uuid('id').primaryKey(),
  site_code: text('site_code').notNull(),
  site_name_zh: text('site_name_zh').notNull(),
  site_name_en: text('site_name_en'),
  province_zh: text('province_zh'),
  province_en: text('province_en'),
  city_zh: text('city_zh'),
  city_en: text('city_en'),
  county_zh: text('county_zh'),
  county_en: text('county_en'),
  location_detail_zh: text('location_detail_zh'),
  location_detail_en: text('location_detail_en'),
  lat: doublePrecision('lat'),
  lng: doublePrecision('lng'),
  precision_level: integer('precision_level'),
  site_type_zh: text('site_type_zh'),
  site_type_en: text('site_type_en'),
  description_zh: text('description_zh'),
  description_en: text('description_en'),
  note_zh: text('note_zh'),
  note_en: text('note_en'),
  created_at: createdAt(),
  period_id: uuid('period_id'),
})

export const contexts = pgTable('contexts', {
  id: uuid('id').primaryKey(),
  context_code: text('context_code').notNull(),
  site_code: text('site_code').notNull(),
  context_name_zh: text('context_name_zh').notNull(),
  context_name_en: text('context_name_en'),
  context_original_code: text('context_original_code'),
  context_type_zh: text('context_type_zh'),
  context_type_en: text('context_type_en'),
  description_zh: text('description_zh'),
  description_en: text('description_en'),
  note_zh: text('note_zh'),
  note_en: text('note_en'),
  created_at: createdAt(),
  period_id: uuid('period_id'),
})

export const finds = pgTable('finds', {
  id: uuid('id').primaryKey(),
  find_code: text('find_code').notNull(),
  context_code: text('context_code').notNull(),
  deprecated_coin_type_code: text('deprecated_coin_type_code'),
  presence: boolean('presence'),
  quantity_total: integer('quantity_total'),
  quantity_min: integer('quantity_min'),
  quantity_max: integer('quantity_max'),
  quantity_estimated: integer('quantity_estimated'),
  quantity_is_estimated: boolean('quantity_is_estimated'),
  total_weight_g: numeric('total_weight_g', { mode: 'number' }),
  quantity_note_zh: text('quantity_note_zh'),
  quantity_note_en: text('quantity_note_en'),
  description_zh: text('description_zh'),
  description_en: text('description_en'),
  note_zh: text('note_zh'),
  note_en: text('note_en'),
  created_at: createdAt(),
  coin_issues_id: uuid('coin_issues_id'),
})

export const coinIssues = pgTable('coin_issues', {
  id: uuid('id').primaryKey(),
  created_at: createdAt(false),
  coin_type_code: text('coin_type_code'),
  description_zh: text('description_zh'),
  description_en: text('description_en'),
  note_zh: text('note_zh'),
  note_en: text('note_en'),
  reverse_inscription: text('reverse_inscription'),
  mint_id: uuid('mint_id'),
  state_id: uuid('state_id'),
  inscription_id: uuid('inscription_id'),
  coin_type_hierarchy_id: uuid('coin_type_hierarchy_id'),
  legacy_type: text('legacy_type'),
  legacy_inscription: text('legacy_inscription'),
  legacy_mint: text('legacy_mint'),
  legacy_state: text('legacy_state'),
})

export const coinTypeHierarchy = pgTable('coin_type_hierarchy', {
  id: uuid('id').primaryKey(),
  level1_zh: text('level1_zh'),
  level1_en: text('level1_en'),
  level2_zh: text('level2_zh'),
  level2_en: text('level2_en'),
  level3_zh: text('level3_zh'),
  level3_en: text('level3_en'),
  level4_zh: text('level4_zh'),
  level4_en: text('level4_en'),
  level5_zh: text('level5_zh'),
  level5_en: text('level5_en'),
  created_at: createdAt(false),
  img_acc_num: text('img_acc_num'),
  name_zh: text('name_zh').notNull(),
  name_en: text('name_en').notNull(),
  description_zh: text('description_zh'),
  description_en: text('description_en'),
  type_code: text('type_code').notNull(),
})

export const mints = pgTable('mints', {
  id: uuid('id').primaryKey(),
  name_zh: text('name_zh').notNull(),
  name_en: text('name_en'),
  precision_level: integer('precision_level'),
  latitude: numeric('latitude', { mode: 'number' }),
  longitude: numeric('longitude', { mode: 'number' }),
  description_zh: text('description_zh'),
  description_en: text('description_en'),
  citation: text('citation'),
  created_at: createdAt(false),
  state_id: uuid('state_id'),
  modern_location_zh: text('modern_location_zh'),
  modern_location_en: text('modern_location_en'),
  location_note: text('location_note'),
  image_ids: uuid('image_ids').array().notNull(),
  sources_unlinked: text('sources_unlinked').array().notNull(),
  mint_code: text('mint_code').notNull(),
  alternative_names: text('alternative_names').array().notNull(),
})

export const states = pgTable('states', {
  id: uuid('id').primaryKey(),
  created_at: createdAt(false),
  state_zh: text('state_zh').notNull(),
  state_en: text('state_en'),
})

export const inscriptions = pgTable('inscriptions', {
  id: uuid('id').primaryKey(),
  inscription_zh: text('inscription_zh').notNull(),
  inscription_en: text('inscription_en'),
  created_at: createdAt(false),
})

export const images = pgTable('images', {
  id: uuid('id').primaryKey(),
  filename: text('filename').notNull(),
  source_id: uuid('source_id'),
  source_text: text('source_text'),
  caption_zh: text('caption_zh'),
  caption_en: text('caption_en'),
  created_at: createdAt(false),
  note_zh: text('note_zh'),
  note_en: text('note_en'),
})

export const sources = pgTable('sources', {
  id: uuid('id').primaryKey(),
  source_code: text('source_code').notNull(),
  author1_zh: text('author1_zh'),
  author1_en: text('author1_en'),
  title_zh: text('title_zh'),
  title_en: text('title_en'),
  language: text('language'),
  year: integer('year'),
  publication_zh: text('publication_zh'),
  publication_en: text('publication_en'),
  page: text('page'),
  citation_zh: text('citation_zh'),
  citation_en: text('citation_en'),
  url: text('url'),
  note_zh: text('note_zh'),
  note_en: text('note_en'),
  created_at: createdAt(),
  type: text('type'),
  editor_zh: text('editor_zh'),
  editor_en: text('editor_en'),
  book_zh: text('book_zh'),
  book_en: text('book_en'),
  place_zh: text('place_zh'),
  place_en: text('place_en'),
  author2_zh: text('author2_zh'),
  author2_en: text('author2_en'),
  author3_zh: text('author3_zh'),
  author3_en: text('author3_en'),
  volume: text('volume'),
  date: text('date'),
  museum: text('museum'),
})

export const sourceLinks = pgTable('source_links', {
  id: uuid('id').primaryKey(),
  source_link_code: text('source_link_code').notNull(),
  source_code: text('source_code').notNull(),
  target_type: text('target_type').notNull(),
  target_code: text('target_code').notNull(),
  page: text('page'),
  note_zh: text('note_zh'),
  note_en: text('note_en'),
  created_at: createdAt(),
})

// ── views (defined in scripts/*.sql; .existing() = never generated by drizzle-kit) ──

export const vCoinMapSites = pgView('v_coin_map_sites', {
  site_code: text('site_code').notNull(),
  site_name_zh: text('site_name_zh'),
  site_name_en: text('site_name_en'),
  province_zh: text('province_zh'),
  province_en: text('province_en'),
  city_zh: text('city_zh'),
  city_en: text('city_en'),
  county_zh: text('county_zh'),
  county_en: text('county_en'),
  lat: doublePrecision('lat'),
  lng: doublePrecision('lng'),
  precision_level: integer('precision_level'),
  site_type_zh: text('site_type_zh'),
  site_type_en: text('site_type_en'),
  find_record_count: bigint('find_record_count', { mode: 'number' }),
  total_quantity_for_map: bigint('total_quantity_for_map', { mode: 'number' }),
  level1_types_zh: text('level1_types_zh'),
  level2_types_zh: text('level2_types_zh'),
  level3_types_zh: text('level3_types_zh'),
  level4_types_zh: text('level4_types_zh'),
  level5_types_zh: text('level5_types_zh'),
  inscriptions: text('inscriptions'),
  states_zh: text('states_zh'),
  mints_zh: text('mints_zh'),
  level1_types_en: text('level1_types_en'),
  level2_types_en: text('level2_types_en'),
  level3_types_en: text('level3_types_en'),
  level4_types_en: text('level4_types_en'),
  level5_types_en: text('level5_types_en'),
  inscriptions_en: text('inscriptions_en'),
  states_en: text('states_en'),
  mints_en: text('mints_en'),
  description_zh: text('description_zh'),
  description_en: text('description_en'),
  period_zh: text('period_zh'),
  period_en: text('period_en'),
}).existing()

export const vCoinIssuesFlat = pgView('v_coin_issues_flat', {
  id: uuid('id').notNull(),
  coin_type_code: text('coin_type_code').notNull(),
  description_zh: text('description_zh'),
  description_en: text('description_en'),
  mint_id: uuid('mint_id'),
  state_id: uuid('state_id'),
  inscription_id: uuid('inscription_id'),
  coin_type_hierarchy_id: uuid('coin_type_hierarchy_id'),
  mint_zh: text('mint_zh'),
  mint_en: text('mint_en'),
  state_zh: text('state_zh'),
  state_en: text('state_en'),
  inscription: text('inscription'),
  inscription_en: text('inscription_en'),
  level2_zh: text('level2_zh'),
  level2_en: text('level2_en'),
  major_type_zh: text('major_type_zh'),
  major_type_en: text('major_type_en'),
  minor_type_zh: text('minor_type_zh'),
  minor_type_en: text('minor_type_en'),
}).existing()

export const vMintStats = pgView('v_mint_stats', {
  mint_id: uuid('mint_id').notNull(),
  mint_code: text('mint_code').notNull(),
  find_count: bigint('find_count', { mode: 'number' }).notNull(),
  coin_count: bigint('coin_count', { mode: 'number' }).notNull(),
  site_count: bigint('site_count', { mode: 'number' }).notNull(),
  inscriptions: text('inscriptions').array().notNull(),
  issue_count: bigint('issue_count', { mode: 'number' }).notNull(),
  type_labels: jsonb('type_labels').$type<MintTypeLabel[]>().notNull(),
}).existing()

export const vCoinFinds = pgView('v_coin_finds', {
  find_code: text('find_code'),
  context_code: text('context_code'),
  site_code: text('site_code'),
  coin_issues_id: uuid('coin_issues_id'),
  coin_type_id: uuid('coin_type_id'),
  quantity_for_map: integer('quantity_for_map').notNull(),
}).existing()
