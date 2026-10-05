import 'server-only'
import { drizzle } from 'drizzle-orm/node-postgres'
import { Pool } from 'pg'
import * as schema from '@/lib/db/schema'

/**
 * Direct Postgres connection for lib/queries.ts's reads — replaces the
 * anon-key supabase-js client there. Connects as the DATABASE_URL role, so
 * RLS doesn't apply; that's fine for these reads since every content table
 * already grants SELECT to public (see DATABASE_QUERIES.md).
 *
 * DATABASE_URL should be Supabase's *transaction pooler* string (port 6543).
 * node-postgres rather than postgres-js: postgres-js wedged Supavisor's
 * transaction mode under `next build`-level concurrency (backends stuck
 * `active`/`ClientRead`, every page timing out), even with pipelining off.
 * `max: 3` keeps `next build`'s 7 prerender workers to ~21 connections.
 * Cached on globalThis so dev-mode HMR doesn't open a new pool per reload.
 */
const globalForDb = globalThis as unknown as { pgPool?: Pool }

function getPool() {
  if (!globalForDb.pgPool) {
    const url = process.env.DATABASE_URL?.trim()
    if (!url) throw new Error('Missing DATABASE_URL in .env.local (Supabase → Connect → Transaction pooler).')
    globalForDb.pgPool = new Pool({ connectionString: url, max: 3 })
  }
  return globalForDb.pgPool
}

export const db = drizzle({ client: getPool(), schema })
