import { createClient } from 'npm:@supabase/supabase-js@2.57.0'

// Public, read-only heartbeat. No service_role key or user data is used.
const SERVICE = 'mfd-api'
const HEADERS = {
  'Cache-Control': 'no-store, max-age=0',
  'Content-Type': 'application/json; charset=utf-8',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, HEAD, OPTIONS',
  'X-Content-Type-Options': 'nosniff',
}

function publicKey(): string | undefined {
  const legacy = Deno.env.get('SUPABASE_ANON_KEY')
  if (legacy) return legacy
  try {
    const keys = JSON.parse(Deno.env.get('SUPABASE_PUBLISHABLE_KEYS') ?? '{}')
    return typeof keys.default === 'string' ? keys.default : undefined
  } catch {
    return undefined
  }
}

function json(req: Request, status: number, state: string, database: string): Response {
  const body = {
    status: state, service: SERVICE, dependencies: { database },
    checked_at: new Date().toISOString(),
  }
  return new Response(req.method === 'HEAD' ? null : JSON.stringify(body), {
    status, headers: HEADERS,
  })
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response(null, { status: 204, headers: HEADERS })
  if (req.method !== 'GET' && req.method !== 'HEAD') {
    return new Response(JSON.stringify({ error: 'METHOD_NOT_ALLOWED' }), {
      status: 405, headers: { ...HEADERS, Allow: 'GET, HEAD, OPTIONS' },
    })
  }
  const url = Deno.env.get('SUPABASE_URL')
  const key = publicKey()
  if (!url || !url.startsWith('https://') || !key) {
    return json(req, 503, 'degraded', 'unavailable')
  }
  try {
    const timedFetch: typeof fetch = (input, init) => fetch(input, {
      ...init, signal: AbortSignal.timeout(4000),
    })
    const client = createClient(url, key, {
      auth: { persistSession: false, autoRefreshToken: false },
      global: { fetch: timedFetch },
    })
    const { data, error } = await client.rpc('saas_heartbeat_v1')
    if (error || data?.status !== 'ok') {
      console.warn('Heartbeat dependency unavailable')
      return json(req, 503, 'degraded', 'unavailable')
    }
    return json(req, 200, 'ok', 'ok')
  } catch {
    console.warn('Heartbeat dependency unavailable')
    return json(req, 503, 'degraded', 'unavailable')
  }
})
