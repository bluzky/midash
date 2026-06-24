# Widget + Connection Guide

Midash widgets use two patterns:

```text
frontend-only: route.svelte -> component/source -> local logic
backend integration: route.svelte -> DataWidget -> source function -> /api/* controller -> lib/midash/* client
```

Prefer frontend-only logic when feature has no backend dependency, secrets, persistence, proxying, or server-side integration. Use backend integration for external services, protected tokens, filesystem/config writes, database access, or logic that must run server-side.

## 1. Backend connection

Create a client module under `lib/midash/`.

```elixir
defmodule Midash.MyService do
  def token, do: Midash.ConfigStore.get("MYSERVICE_TOKEN", "")

  def fetch_items do
    token = token()

    cond do
      token == "" ->
        {:error, "MYSERVICE_TOKEN not configured"}

      true ->
        # call remote API
        {:ok, [%{title: "example"}]}
    end
  end
end
```

Rules:

- Read runtime config via `Midash.ConfigStore.get/2`, not `System.get_env/1`.
- Return `{:error, "CONFIG_KEY not configured"}` for missing config.
- Do not crash on missing/invalid URL; return `{:error, reason}`.
- Keep remote API parsing in `lib/midash/*`, not controller.

## 2. API controller

Create controller under `lib/midash_web/controllers/api/`.

```elixir
defmodule MidashWeb.API.MyServiceController do
  use MidashWeb, :controller

  alias Midash.MyService

  def items(conn, _params) do
    case MyService.fetch_items() do
      {:ok, items} -> json(conn, %{data: items})
      {:error, reason} -> conn |> put_status(502) |> json(%{error: reason})
    end
  end
end
```

Add route in `lib/midash_web/router.ex` under `/api` scope:

```elixir
get "/my-service/items", API.MyServiceController, :items
```

## 3. Frontend source function

Create `assets/svelte/lib/sources/my-service.js`.

Sources return a descriptor object `{ key, fetch, staleTime? }` — not a plain async function. `DataWidget` passes this to TanStack Query automatically.

```js
import { get } from '../api.js'

export function myServiceItems() {
  return {
    key: '/api/my-service/items',   // cache key — must be unique per logical query
    staleTime: 60,                   // optional, seconds (default 60)
    async fetch() {
      const res = await get('/api/my-service/items')
      return {
        columns: [
          { key: 'title', label: 'title' },
          { key: 'status', label: 'status' },
        ],
        rows: res.data.map((item) => ({
          title: item.title,
          status: item.status ?? 'unknown',
        })),
      }
    },
  }
}
```

If the source takes params that affect the result, include them in `key`:

```js
export function myServiceItems({ filter = 'all' } = {}) {
  return {
    key: `/api/my-service/items?filter=${filter}`,
    async fetch() {
      const res = await get(`/api/my-service/items?filter=${filter}`)
      // ...
    },
  }
}
```

If two sources call the same URL but produce different shapes, use a `#suffix` to distinguish the cache keys:

```js
export function clickupTasks({ mode = 'count' } = {}) {
  return {
    key: `/api/clickup/tasks#${mode}`,
    async fetch() { /* ... */ },
  }
}
```

Frontend-only source (no backend call):

```js
export function localStats() {
  return {
    key: 'local#stats',
    fetch: async () => ({
      items: [
        { label: 'loaded', value: performance.getEntriesByType('resource').length },
        { label: 'timezone', value: Intl.DateTimeFormat().resolvedOptions().timeZone },
      ],
    }),
  }
}
```

`DataWidget` expects shape based on display type:

| Display | Data shape |
|---------|------------|
| `table` | `{ columns: [...], rows: [...] }` |
| `list` | `{ items: [...] }` |
| `tabs-list` | `{ tabs: [{ key, label, count, items }] }` |
| `stat` | `{ value, label, trend, delta }` |
| `stat-group` | `{ items: [{ value, label, trend, delta }] }` |
| `key-value` | `{ pairs: [{ key, value, meta, status }] }` |
| `status-grid` | `{ items: [{ name, status, meta, href }] }` |
| `progress` | `{ items: [{ label, value, max, color }] }` |
| `feed` | `{ items: [{ title, body, author, time, href }] }` |
| `timeline` | `{ events: [{ title, body, time, status, href }] }` |
| `markdown` | `{ content }` |
| `line-chart` / `area-chart` | `{ series: [{ name, color, data }] }` |

## 4. Add to route

Use `DataWidget` for standard widgets. Source functions may call backend APIs or compute data locally when logic is frontend-only.

```svelte
<script>
  import DashboardLayout from '../components/DashboardLayout.svelte'
  import Col from '../components/Col.svelte'
  import DataWidget from '../components/DataWidget.svelte'
  import { myServiceItems } from '../lib/sources/my-service.js'
</script>

<DashboardLayout>
  <Col span={6}>
    <DataWidget
      title="my service"
      collapsible
      display="table"
      source={myServiceItems()}
      config={{ sortable: true }}
      configGroup="MYSERVICE_TOKEN"
      poll={120}
    />
  </Col>
</DashboardLayout>
```

Props:

- `title` — widget title.
- `display` — display component key.
- `source` — source descriptor `{ key, fetch, staleTime? }` from a sources file.
- `config` — display-specific options.
- `configGroup` — config key group for configure dialog fallback on API errors.
- `poll` — seconds between auto-refreshes (`refetchInterval`).
- `collapsible` — enables collapse button.

## 5. Caching

`DataWidget` uses **TanStack Query** (`@tanstack/svelte-query`). The `QueryClient` is set up in `App.svelte` with a 60s default `staleTime`.

Behaviour out of the box:
- Navigate away and back → cached data renders instantly; background refetch happens silently
- Manual refresh → keeps showing old data while fetching (no spinner flash)
- Concurrent widgets hitting the same URL → `api.js` deduplicates the HTTP request to one

For bespoke route components that can't use `DataWidget`, call `createQuery` directly:

```svelte
<script>
  import { createQuery } from '@tanstack/svelte-query'
  import { get } from '../lib/api.js'

  const q = createQuery(() => ({
    queryKey: ['/api/my-endpoint'],
    queryFn: () => get('/api/my-endpoint').then(r => r.data),
    staleTime: 30_000,
    refetchInterval: 60_000,
  }))
</script>

{#if q.isPending}
  <Spinner />
{:else if q.isError}
  <div class="text-destructive text-sm">{q.error.message}</div>
{:else}
  <!-- render q.data -->
{/if}
```

Note: `createQuery` takes a **function** `() => options`, not a plain object.

## 6. Config schema

Frontend config fields live in one central file:

```text
assets/svelte/lib/config-schema.js
```

Add new service config there:

```js
const MYSERVICE_FIELDS = [
  { key: 'MYSERVICE_TOKEN', label: 'MyService token', secret: true },
  { key: 'MYSERVICE_URL', label: 'MyService URL', placeholder: 'https://example.com' },
]

export const CONFIG_GROUPS = {
  // ...
  MYSERVICE_TOKEN: MYSERVICE_FIELDS,
  MYSERVICE_URL: MYSERVICE_FIELDS,
}

export const CONFIG_TITLES = {
  // ...
  MYSERVICE_TOKEN: 'Configure MyService',
  MYSERVICE_URL: 'Configure MyService',
}
```

Backend allowed config keys live in:

```text
lib/midash_web/controllers/api/config_controller.ex
```

Add every key to `@config_keys`:

```elixir
@config_keys ~w(
  MYSERVICE_TOKEN
  MYSERVICE_URL
)
```

Config saves to local `.midash_config.json`. File values override environment variables.

## 7. Missing config behavior

If backend returns:

```text
MYSERVICE_TOKEN not configured
```

`DataWidget` extracts `MYSERVICE_TOKEN`, looks it up in `config-schema.js`, and shows configure button.

If remote API returns any other error, `DataWidget` still shows configure button when `configGroup` is set:

```svelte
<DataWidget configGroup="MYSERVICE_TOKEN" ... />
```

## 8. Custom widget component

Use custom component when `DataWidget` display types are not enough.

```svelte
<script>
  import Widget from '../components/Widget.svelte'
  import Spinner from '../components/Spinner.svelte'
  import { get } from '../lib/api.js'

  let data = $state(null)
  let loading = $state(true)
  let error = $state(null)

  export async function refresh() {
    loading = true
    error = null
    try {
      data = await get('/api/my-service/custom')
    } catch (e) {
      error = e.message
    } finally {
      loading = false
    }
  }

  refresh()
</script>

<Widget title="custom" onRefresh={refresh}>
  {#if loading}
    <Spinner />
  {:else if error}
    <div class="text-destructive text-sm">{error}</div>
  {:else}
    <!-- custom UI -->
  {/if}
</Widget>
```

## 9. Verify

Run both:

```bash
mix compile
npm run build --prefix assets
```
