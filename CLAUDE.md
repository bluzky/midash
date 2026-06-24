# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Midash is a personal dashboard app built with **Phoenix 1.7** (JSON API + WebSocket backend) and **Svelte 5** (SPA frontend). No LiveView — Phoenix serves JSON only; the Svelte SPA handles all routing and UI.

## Common Commands

```bash
mix setup                  # Install deps, create DB, build assets
mix phx.server             # Start dev server on localhost:4000
iex -S mix phx.server      # Start with interactive shell
mix test                   # Run all tests
mix ecto.migrate           # Run pending migrations
mix ecto.reset             # Drop + recreate + seed DB
npm run build              # Build frontend (run from assets/)
npm run dev                # Frontend watch mode (run from assets/)
```

## Architecture

### Router

Three scopes — no LiveView routes:

- `/api/*` → JSON controllers in `lib/midash_web/controllers/api/`
- `/bin/:bin_id/*` → `RequestBinPlug` (PostBin HTTP capture)
- `/*` → `PageController.index` — serves bare HTML shell that loads the Svelte bundle

### Frontend (Svelte 5 SPA)

All UI lives in `assets/svelte/`:

```
assets/svelte/
├── main.js                    # Entry point
├── App.svelte                 # Root + client-side router (match() on pathname)
├── components/
│   ├── DashboardLayout.svelte # Nav + 12-column grid wrapper
│   ├── Col.svelte             # Column (span prop 1–12 → col-span-{n})
│   ├── Widget.svelte          # Card with title, collapsible, onRefresh
│   └── Spinner.svelte         # Centered loading spinner
├── lib/
│   ├── api.js                 # fetch wrapper with CSRF token
│   ├── router.svelte.js       # popstate-based SPA router
│   └── indicators/            # Reusable chart indicator modules (see below)
├── routes/                    # Page components (one per dashboard page)
└── widgets/                   # Widget components (fetch from /api/*)
```

### Layout Model

Every route uses: `DashboardLayout` → `Col` → `Widget` → widget component.

```svelte
<DashboardLayout>
  <Col span={6}>
    <Widget title="my prs" collapsible onRefresh={() => widget?.refresh()}>
      <GithubMyPRs bind:this={widget} repos={REPOS} />
    </Widget>
  </Col>
</DashboardLayout>
```

### Widget Pattern

Widgets are Svelte components in `assets/svelte/widgets/`. Standard shape:

- Fetch from `/api/*` via `get()` from `lib/api.js`
- Use `$state` for `data`, `loading`, `error`
- Show `<Spinner />` while loading (not text)
- Export `fetch` as `refresh` so parent can trigger manual refresh
- Use `bind:this={widgetRef}` in the route and pass `onRefresh={() => widgetRef?.refresh()}` to `Widget`

### Adding a New Page

1. Create `assets/svelte/routes/MyPage.svelte`
2. Add route in `App.svelte` `match()` function
3. Add nav entry in `Nav.svelte` `PAGES` array

### Adding a New Widget

1. Create `assets/svelte/widgets/MyWidget.svelte` following the widget pattern above
2. Add a JSON endpoint in `lib/midash_web/controllers/api/` + route in `router.ex`
3. Import and use the widget in the relevant route

### CryptoChart Widget

`assets/svelte/widgets/CryptoChart.svelte` renders a candlestick chart (lightweight-charts v5) for a single symbol with volume histogram and PDH/PDL price lines. It auto-refreshes every 60 seconds.

**Props:**
- `symbol` — Binance trading pair, e.g. `'ETHUSDT'` (default: `'ETHUSDT'`)
- `indicators` — array of indicator instances (default: `[bollingerBands(), ema(9), ema(21, pink), macd()]`)

**Usage:**
```svelte
<CryptoChart symbol="ETHUSDT" />
<CryptoChart symbol="BTCUSDT" indicators={[bollingerBands({ period: 14 })]} />
<CryptoChart symbol="ETHUSDT" indicators={[]} />  <!-- no indicators -->
```

The Crypto route (`routes/Crypto.svelte`) renders one `Widget + CryptoChart` per symbol in a 2-per-row grid.

### Chart Indicators

Indicators live in `assets/svelte/lib/indicators/`. Each file exports a factory function that returns an object with three fields:

```js
{
  name: string,            // display label for toggle button
  color: string,           // swatch color for toggle button
  warmup: number,          // extra candles to fetch for initialization
  panel?: { height, scaleId },  // present only for panel indicators
  compute(allMapped),      // pure fn: candle array → computed data array
  mount(chart),            // adds series to chart; returns { setAll, updateLast, setVisible, destroy }
}
```

`CryptoChart` drives the lifecycle automatically: it fetches `VISIBLE + max(warmup)` candles, calls `compute` on each refresh, and calls `mount` once on chart creation (then `setAll`/`updateLast` on each refresh, `destroy` on unmount).

**Available indicators** (`lib/indicators/index.js`):
- `bollingerBands({ period = 20, mult = 2 })` — Bollinger Bands (upper/middle/lower). Main pane.
- `ema({ period = 9, color = '#EAB308' })` — Exponential Moving Average (single line). Main pane.
- `macd({ fast = 12, slow = 26, signal = 9 })` — MACD histogram + MACD/signal lines. Separate panel below candles.

**Panel indicators** declare `panel: { height, scaleId }` on the factory return. `CryptoChart` automatically stacks panels below the candle area (above volume), computing `scaleMargins` for each. Panel `mount(chart, { scaleId, scaleMargins })` receives the computed margins and applies them to its price scale.

**Adding a new indicator:**

1. Create `assets/svelte/lib/indicators/myIndicator.js`:

```js
import { LineSeries } from 'lightweight-charts'

export function myIndicator({ period = 14 } = {}) {
  return {
    name: 'MyInd',
    color: '#ffffff',
    warmup: period,
    compute(candles) {
      // return array of { time, ...values }
    },
    mount(chart) {
      const series = chart.addSeries(LineSeries, { color: '#fff', lineWidth: 1, lastValueVisible: false, priceLineVisible: false })
      return {
        setAll(data) { series.setData(data.map((d) => ({ time: d.time, value: d.myValue }))) },
        updateLast(data) { for (const d of data.slice(-2)) series.update({ time: d.time, value: d.myValue }) },
        setVisible(v) { series.applyOptions({ visible: v }) },
        destroy() { chart.removeSeries(series) },
      }
    },
  }
}
```

2. Re-export from `lib/indicators/index.js`
3. Pass to `CryptoChart`: `indicators={[bollingerBands(), myIndicator()]}`

### API Layer

Use `get`, `post`, `del` from `assets/svelte/lib/api.js`. CSRF token is read from the Phoenix-injected meta tag automatically.

For data fetching patterns, source functions, caching, and `DataWidget` usage see **`docs/widget-guide.md`**.

## Task Management

Use **Trekker** (`trekker` CLI) to manage tasks. Data is stored in `.trekker/trekker.db`.

```bash
trekker init                                      # Initialize (first time)
trekker --toon task list --status in_progress     # Check what's in progress at session start
trekker --toon task list --status todo            # See backlog
trekker task create -t "Title" [-d "desc"] [-e <epic-id>]
trekker task update <task-id> -s in_progress      # Mark when starting
trekker task update <task-id> -s completed        # Mark when done
trekker comment add <task-id> -a "agent" -c "..."  # Add summary before completing
```

**Workflow rules:**
1. At session start, check `in_progress` tasks first — read the task + comments for context
2. Set status to `in_progress` when starting a task, `completed` when done
3. Add a summary comment before marking complete
4. Add a checkpoint comment before context resets: what's done, what's next, which files

## Styling

See **`DESIGN.md`** for the full design system — colors, typography, spacing, border radius, and component guidelines. Always consult it before making visual decisions.

Key rules:
- **Tailwind CSS** + **Bits UI** for accessible components (Tabs, Collapsible, ToggleGroup)
- Border radius: always use `rounded-lg` / `rounded-md` / `rounded-sm` (map to `var(--radius)` CSS variable) — never bare `rounded`
- Font sizes: `text-sm` for primary content labels, `text-xs` for metadata (timestamps, counts, secondary info)
- Loading states: `<Spinner />` component, never "fetching..." text
