# Midash

A personal dashboard app built with Phoenix 1.7, LiveView 1.0, Tailwind CSS, and CubDB. Displays widgets in a glance-style column layout with real-time updates.

## Features

- **Glance-style dashboard** — widgets stack vertically in flexible columns (3, 4, 6, 8, 9, or 12 column spans)
- **LiveView components** — real-time widget updates with minimal overhead
- **Multiple pages** — Home, Work, Monitor, and Metrics dashboards
- **Dark monochrome theme** — minimal, focused UI with Tailwind utilities
- **Widgets included:**
  - GitHub PRs (by developer, personal, pending review)
  - ClickUp task counts and lists
  - Sentry issue monitoring
  - Quick notes

## Prerequisites

- Elixir 1.14+
- OTP 25+
- Node.js 16+ (for frontend assets)

## Quick Start

### 1. Install dependencies

```bash
mix setup
```
### 2. Configure environment variables (optional)

Copy `env.sample` to `.env` for optional integrations:

```bash
cp env.sample .env
```

Edit `.env` with your configuration (see [Environment Variables](#environment-variables) section below for optional API tokens).

### 3. Start the development server

```bash
source .env && mix phx.server
```

Visit [`http://localhost:4000`](http://localhost:4000)

Or start with interactive shell:

```bash
source .env && iex -S mix phx.server
```


## Project Structure

```
lib/
├── midash/
│   ├── sentry.ex              # Sentry API client
│   └── ...
├── midash_web/
│   ├── components/
│   │   ├── dashboard_components.ex  # dashboard_layout, col, widget, nav
│   │   └── layouts/
│   ├── live/
│   │   ├── home_live.ex       # Home dashboard
│   │   ├── work_live.ex       # Work dashboard
│   │   ├── monitor_live.ex    # Sentry monitoring dashboard
│   │   ├── metrics_live.ex    # Metrics dashboard
│   │   └── ...
│   ├── widgets/               # LiveComponent widgets
│   ├── nav.ex                 # Shared navigation config
│   └── router.ex              # Routes
├── assets/                    # Frontend (JS, CSS)
└── priv/
    └── static/               # Images, fonts
```

## Architecture

### Dashboard Pages

Every page is a LiveView (`*_live.ex`) that renders a **glance-style column layout**:

```elixir
<.dashboard_layout current={MidashWeb.Nav.current_from_module(__MODULE__)}>
  <.col span={3}>
    <.widget title="Clock">
      <.live_component module={WorldClockWidget} id="clock" />
    </.widget>
  </.col>
  <.col span={6}>
    <!-- more widgets -->
  </.col>
</.dashboard_layout>
```

Flow: Router → LiveView → `dashboard_layout` → `col` components → `widget` cards → `live_component` widgets

### Navigation

Navigation is centralized in `lib/midash_web/nav.ex`:

```elixir
MidashWeb.Nav.pages()  # Get all nav pages
MidashWeb.Nav.current_from_module(__MODULE__)  # Auto-detect active page
```

Each LiveView passes the current page to `dashboard_layout`, which auto-highlights the active nav item.

### Widgets

Widgets are `live_component` modules in `lib/midash_web/widgets/`:

**Self-updating widgets:**
1. Widget calls `Process.send_after(self(), {:some_tick, id}, interval)` in `update/2`
2. Parent LiveView handles the tick in `handle_info/2` and sends update: `send_update(WidgetModule, id: id)`
3. Note: `handle_info` is **not** valid on `live_component` (only on the parent LiveView)

## Styling

- **Theme system** — CSS custom properties in `assets/css/`
- **Tailwind utilities** — all styling via Tailwind classes (no custom CSS)
- **Dark monochrome** — `#0d0d0d` background, `#141414` cards, minimal borders
- **Monospace font** — throughout entire UI

## Adding a New Page

1. Create a LiveView in `lib/midash_web/live/my_live.ex`
2. Add route in `lib/midash_web/router.ex`:
   ```elixir
   live "/mypage", MyLive
   ```
3. Add nav entry in `lib/midash_web/nav.ex`:
   ```elixir
   %{id: :mypage, label: "my page", path: "/mypage"}
   ```
4. Add case in `Nav.current_from_module/1`:
   ```elixir
   MidashWeb.MyLive -> :mypage
   ```

## Adding a New Widget

1. Create `lib/midash_web/widgets/my_widget.ex` as a `live_component`:
   ```elixir
   defmodule MidashWeb.Widgets.MyWidget do
     use MidashWeb, :live_component

     def mount(socket), do: {:ok, socket}
     def update(assigns, socket), do: {:ok, assign(socket, assigns)}
     def render(assigns), do: ~H"<div>...</div>"
   end
   ```
2. Drop it into a page:
   ```heex
   <.widget title="My Widget">
     <.live_component module={MyWidget} id="my-widget" />
   </.widget>
   ```

## Environment Variables

All environment variables are optional. Add them to `.env` to enable integrations:

| Variable | Purpose |
|----------|---------|
| `SENTRY_TOKEN` | Sentry API authentication for monitoring dashboard |
| `SENTRY_PROJECTS` | Projects to monitor (comma-separated, format: `org/project:env1:env2`) |
| `GITHUB_TOKEN` | GitHub API authentication for Work page widgets |
| `GITHUB_USERNAME` | GitHub username for filtering PRs |
| `CLICKUP_TOKEN` | ClickUp API authentication for Work page widgets |
| `CLICKUP_TEAM_ID` | ClickUp team ID |
| `CLICKUP_USER_ID` | ClickUp user ID |

