defmodule MidashWeb.DashboardComponents do
  use Phoenix.Component
  use MidashWeb, :verified_routes

  @moduledoc """
  Components for building glance-style dashboard pages.

  Layout model: a 12-column CSS grid. Each column declares how many grid columns it spans (3, 4, 6, 8, or 12).
  Widgets stack vertically inside each column.

  ## Page layout example

      <.dashboard_layout nav_pages={@nav_pages} current={:home}>
        <.col span={3}>
          <.widget title="Clock">
            <.live_component module={ClockWidget} id="clock" />
          </.widget>
        </.col>

        <.col span={6}>
          <.widget title="News">
            <.live_component module={HackerNewsWidget} id="hn" />
          </.widget>
        </.col>

        <.col span={3}>
          <.widget title="Markets">
            <.live_component module={MarketsWidget} id="markets" />
          </.widget>
        </.col>
      </.dashboard_layout>
  """

  @doc """
  Full page wrapper: nav + columns layout.
  """
  attr :nav_pages, :list, required: true
  attr :current, :atom, required: true
  slot :inner_block, required: true

  def dashboard_layout(assigns) do
    ~H"""
    <div class="min-h-screen bg-background text-foreground font-mono">
      <.dashboard_nav current={@current} pages={@nav_pages} />
      <div class="grid grid-cols-12 gap-4 p-4 items-start">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  @themes [
    %{id: "dark", label: "Dark"},
    %{id: "light", label: "Light"},
    %{id: "ocean", label: "Ocean"},
    %{id: "forest", label: "Forest"},
    %{id: "sunset", label: "Sunset"},
    %{id: "midnight", label: "Midnight"},
    %{id: "nord", label: "Nord"},
    %{id: "latte", label: "Latte"},
    %{id: "paper", label: "Paper"},
    %{id: "rose", label: "Rose"},
    %{id: "mint", label: "Mint"}
  ]

  @doc """
  Horizontal navigation bar.
  - `current` - atom of active page
  - `pages`   - list of `%{id: atom, label: string, path: string}`
  """
  attr :current, :atom, required: true
  attr :pages, :list, required: true

  def dashboard_nav(assigns) do
    assigns = assign(assigns, :themes, @themes)

    ~H"""
    <nav class="flex items-center gap-1 border-b border-border bg-background px-4 py-2">
      <span class="text-muted-foreground text-xs mr-3 select-none tracking-wide">midash</span>
      <%= for page <- @pages do %>
        <.link
          navigate={page.path}
          class={[
            "px-3 py-1.5 text-sm rounded-md transition-colors",
            if(page.id == @current,
              do: "bg-secondary text-foreground",
              else: "text-muted-foreground hover:text-foreground hover:bg-secondary/50"
            )
          ]}
        >
          {page.label}
        </.link>
      <% end %>
      <%!-- Theme switcher dropdown --%>
      <div class="ml-auto relative" id="theme-switcher" phx-hook="ThemeSwitcher">
        <button
          id="theme-menu-btn"
          class="flex items-center gap-1.5 rounded-sm px-2 py-1.5 text-xs text-muted-foreground hover:text-foreground hover:bg-secondary transition-colors"
          title="switch theme"
          onclick="document.getElementById('theme-menu').classList.toggle('hidden')"
        >
          <Lucideicons.palette class="w-4 h-4" aria-hidden="true" />
          <span id="theme-label">theme</span>
          <Lucideicons.chevron_down class="w-3 h-3" aria-hidden="true" />
        </button>
        <div
          id="theme-menu"
          class="hidden absolute right-0 top-full mt-1 z-50 min-w-[8rem] rounded-md border border-border bg-card shadow-lg py-1"
        >
          <%= for theme <- @themes do %>
            <button
              class="w-full flex items-center gap-2 px-3 py-1.5 text-xs text-left text-muted-foreground hover:text-foreground hover:bg-secondary transition-colors"
              phx-click={Phoenix.LiveView.JS.dispatch("phx:set-theme", detail: %{theme: theme.id})}
              onclick={"setTheme('#{theme.id}'); document.getElementById('theme-menu').classList.add('hidden')"}
            >
              <span class={[
                "w-2.5 h-2.5 rounded-full border border-border flex-shrink-0",
                theme_swatch_class(theme.id)
              ]}>
              </span>
              {theme.label}
            </button>
          <% end %>
        </div>
      </div>
    </nav>
    """
  end

  defp theme_swatch_class("dark"), do: "bg-[#141414]"
  defp theme_swatch_class("light"), do: "bg-white"
  defp theme_swatch_class("ocean"), do: "bg-[#0d2233]"
  defp theme_swatch_class("forest"), do: "bg-[#0a1a0f]"
  defp theme_swatch_class("sunset"), do: "bg-[#1f100a]"
  defp theme_swatch_class("midnight"), do: "bg-[#0e0b1f]"
  defp theme_swatch_class("nord"), do: "bg-[#1e2433]"
  defp theme_swatch_class("latte"), do: "bg-[#f5ede0]"
  defp theme_swatch_class("paper"), do: "bg-[#f3f4f8]"
  defp theme_swatch_class("rose"), do: "bg-[#fdf0f3]"
  defp theme_swatch_class("mint"), do: "bg-[#eef7f3]"
  defp theme_swatch_class(_), do: "bg-secondary"

  @doc """
  A vertical column that spans a number of grid columns (out of 12).

  - `span` - number of columns to span: `3`, `4`, `6`, `8`, `9`, or `12` (default `6`)
  """
  attr :span, :integer, default: 6
  slot :inner_block, required: true

  def col(assigns) do
    ~H"""
    <div class={col_class(@span)}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Widget card: optional title bar + content area.

  - `id` - unique identifier (required when `collapsible` is true)
  - `title` - optional string shown in header
  - `on_refresh` - a `%JS{}` command to run when the refresh button is clicked (shows button when set)
  - `collapsible` - show a collapse/expand toggle in the title bar (default false)
  """
  attr :id, :string, default: nil
  attr :title, :string, default: nil
  attr :class, :string, default: nil
  attr :on_refresh, :any, default: nil
  attr :collapsible, :boolean, default: false
  slot :inner_block, required: true

  def widget(assigns) do
    ~H"""
    <div class={["mb-4 rounded-lg border border-border bg-card shadow-sm last:mb-0", @class]}>
      <div
        :if={@title}
        class="px-4 py-2.5 border-b border-border text-xs text-muted-foreground uppercase tracking-widest flex items-center justify-between"
      >
        <span>{@title}</span>
        <span :if={@on_refresh || @collapsible} class="flex items-center gap-1">
          <button
            :if={@on_refresh}
            phx-click={@on_refresh}
            class="rounded-sm p-1 text-muted-foreground hover:text-foreground hover:bg-secondary transition-colors"
            title="refresh"
          >
            <Lucideicons.rotate_cw class="w-3.5 h-3.5" aria-hidden="true" />
          </button>
          <button
            :if={@collapsible}
            phx-click={Phoenix.LiveView.JS.toggle(to: "##{@id}-content")}
            class="rounded-sm p-1 text-muted-foreground hover:text-foreground hover:bg-secondary transition-colors"
            title="collapse"
          >
            <Lucideicons.chevron_down class="w-3.5 h-3.5" aria-hidden="true" />
          </button>
        </span>
      </div>
      <div id={if @id, do: "#{@id}-content"} class="p-4">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  # --- Helpers ---

  # Explicit class strings so Tailwind's scanner keeps them in the bundle.
  defp col_class(3), do: "col-span-3 min-w-0"
  defp col_class(4), do: "col-span-4 min-w-0"
  defp col_class(6), do: "col-span-6 min-w-0"
  defp col_class(8), do: "col-span-8 min-w-0"
  defp col_class(9), do: "col-span-9 min-w-0"
  defp col_class(12), do: "col-span-12 min-w-0"
  defp col_class(_), do: "col-span-6 min-w-0"
end
