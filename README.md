# Midash

A personal dashboard app built with **Phoenix 1.7** (JSON API + WebSocket) and **Svelte 5** (SPA frontend). Displays widgets in a glance-style column layout with auto-polling.

## Features

- **Glance-style dashboard** — widgets stack vertically in flexible columns
- **Svelte 5 SPA** — client-side routing, reactive state, auto-polling widgets
- **Dark monochrome theme** — minimal UI with Tailwind + Bits UI components
- **Widgets included:**
  - GitHub PRs (by developer, personal, pending review)
  - ClickUp task counts and lists
  - Sentry issue monitoring
  - ArgoCD app status
  - Crypto funding rates and candlestick charts
  - World clock
- **Toolkit** — Elixir Execute, Barcode Generator, PostBin, Mau Templates, Map→JSON

## Prerequisites

- Elixir 1.14+ / OTP 25+
- Node.js 18+

## Quick Start

```bash
mix setup                        # install deps, create DB, build assets
cp env.sample .env               # copy env template
source .env && mix phx.server    # start server at http://localhost:4000
```

Or with interactive shell:

```bash
source .env && iex -S mix phx.server
```

## Common Commands

```bash
mix phx.server          # start dev server
mix test                # run tests
mix ecto.migrate        # run pending migrations
mix ecto.reset          # drop + recreate + seed DB
npm run build           # build frontend (from assets/)
npm run dev             # frontend watch mode (from assets/)
```

## Project Structure

```
lib/
├── midash/                         # Business logic, API clients
│   ├── clickup.ex
│   ├── argocd.ex
│   └── ...
└── midash_web/
    ├── controllers/
    │   ├── api/                    # JSON API controllers
    │   │   ├── clickup_controller.ex
    │   │   ├── github_controller.ex
    │   │   ├── sentry_controller.ex
    │   │   ├── argocd_controller.ex
    │   │   ├── crypto_controller.ex
    │   │   ├── toolkit_controller.ex
    │   │   └── postbin_controller.ex
    │   └── page_controller.ex      # SPA shell (serves index.html)
    ├── channels/
    │   ├── user_socket.ex
    │   └── postbin_channel.ex      # WebSocket for PostBin
    ├── plugs/
    │   └── request_bin_plug.ex     # HTTP capture for PostBin
    └── router.ex

assets/svelte/
├── main.js                         # Svelte entry point
├── App.svelte                      # Root component + client-side router
├── components/
│   ├── DashboardLayout.svelte      # Nav + full-page grid wrapper
│   ├── Nav.svelte                  # Top nav bar
│   ├── Col.svelte                  # Flex column (span prop)
│   ├── Widget.svelte               # Card wrapper with title + collapsible
│   └── Spinner.svelte              # Centered loading spinner
├── lib/
│   ├── api.js                      # fetch wrapper with CSRF
│   ├── router.svelte.js            # popstate-based SPA router
│   └── themes.js                   # theme utilities
├── routes/
│   ├── Home.svelte
│   ├── Work.svelte
│   ├── Crypto.svelte
│   ├── Monitor.svelte
│   ├── ArgoCD.svelte
│   ├── Toolkit.svelte
│   └── toolkit/                    # Individual toolkit pages
└── widgets/
    ├── GithubPRs.svelte
    ├── GithubMyPRs.svelte
    ├── GithubPendingReview.svelte
    ├── ClickupTasks.svelte
    ├── SentryIssues.svelte
    ├── ArgoCDApps.svelte
    ├── CryptoFunding.svelte
    ├── CryptoChart.svelte
    └── WorldClock.svelte
```

## Architecture

### Routing

The Phoenix router serves three scopes:

- `/api/*` — JSON controllers (no HTML, no LiveView)
- `/bin/:bin_id/*` — PostBin HTTP capture plug
- `/*` — SPA shell: `PageController.index` renders a bare HTML page that loads the Svelte bundle

Client-side routing in `App.svelte` matches the URL path and renders the appropriate route component.

### Layout Model

Every route uses `DashboardLayout` → `Col` → `Widget` → widget component:

```svelte
<DashboardLayout>
  <Col span={6}>
    <Widget title="my prs" collapsible onRefresh={() => widget?.refresh()}>
      <GithubMyPRs bind:this={widget} repos={REPOS} />
    </Widget>
  </Col>
</DashboardLayout>
```

`Col` accepts a `span` prop (1–12, maps to `col-span-{n}` in the 12-column grid).  
`Widget` accepts `title`, `collapsible` (boolean), and `onRefresh` (callback shown as a button).

### Adding a New Page

1. Create `assets/svelte/routes/MyPage.svelte` using `DashboardLayout` + `Col` + `Widget`
2. Import and add a route entry in `App.svelte`:
   ```svelte
   import MyPage from './routes/MyPage.svelte'
   // in match():
   case '/mypage': return MyPage
   ```
3. Add nav entry in `Nav.svelte`:
   ```js
   const PAGES = [
     ...
     { label: 'my page', path: '/mypage' },
   ]
   ```

### Adding a New Widget

1. Create `assets/svelte/widgets/MyWidget.svelte`:
   ```svelte
   <script>
     import { get } from '../lib/api.js'
     import Spinner from '../components/Spinner.svelte'

     let data = $state([])
     let loading = $state(true)
     let error = $state(null)

     async function fetch() {
       loading = true
       error = null
       try {
         const res = await get('/api/my-endpoint')
         data = res.data
       } catch (e) {
         error = e.message
       } finally {
         loading = false
       }
     }

     export { fetch as refresh }
     fetch()
   </script>

   {#if loading}
     <Spinner />
   {:else if error}
     <div class="text-destructive text-sm">{error}</div>
   {:else}
     <!-- render data -->
   {/if}
   ```
2. Export `refresh` to allow the parent `Widget` to trigger a manual refresh via `onRefresh`.
3. Drop it into a route with `bind:this={widgetRef}` to wire up the refresh button.

### API Layer

All data fetching goes through `assets/svelte/lib/api.js`:

```js
import { get, post, del } from '../lib/api.js'

const res = await get('/api/clickup/tasks')
const res = await post('/api/toolkit/execute', { code, input })
```

CSRF token is read from the meta tag injected by Phoenix and sent on every mutating request.

### Styling

- **Tailwind CSS** + **Bits UI** for accessible components (tabs, collapsible, toggle groups)
- Border radius uses Bits UI CSS variables: `rounded-lg` = `var(--radius)`
- Dark monochrome theme: `#0d0d0d` background, `#141414` cards, monospace font throughout
- Loading states use `<Spinner />` (centered, horizontally)
- Font sizes: `text-sm` for primary content, `text-xs` for metadata (timestamps, counts)

## Environment Variables

All variables are optional. Add to `.env` to enable integrations:

| Variable | Purpose |
|----------|---------|
| `GITHUB_TOKEN` | GitHub API authentication |
| `GITHUB_USERNAME` | GitHub username for filtering your PRs |
| `CLICKUP_TOKEN` | ClickUp API authentication |
| `CLICKUP_TEAM_ID` | ClickUp team ID |
| `CLICKUP_USER_ID` | ClickUp user ID |
| `SENTRY_TOKEN` | Sentry API authentication |
| `VITE_SENTRY_PROJECTS` | Projects to monitor — format: `org/project:env1:env2,...` |
| `ARGOCD_URL` | ArgoCD base URL |
| `ARGOCD_TOKEN` | ArgoCD API token |
