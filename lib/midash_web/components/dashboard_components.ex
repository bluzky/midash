defmodule MidashWeb.DashboardComponents do
  use Phoenix.Component
  use MidashWeb, :verified_routes

  @moduledoc """
  Components for building glance-style dashboard pages.

  Layout model: columns stacked side-by-side, widgets stacked vertically inside each column.

  ## Page layout example

      <.dashboard_layout nav_pages={@nav_pages} current={:home}>
        <.col size={:small}>
          <.widget title="Clock">
            <.live_component module={ClockWidget} id="clock" />
          </.widget>
        </.col>

        <.col size={:full}>
          <.widget title="News">
            <.live_component module={HackerNewsWidget} id="hn" />
          </.widget>
        </.col>

        <.col size={:small}>
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
      <div class="flex gap-4 p-4 items-start">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  @doc """
  Horizontal navigation bar.
  - `current` - atom of active page
  - `pages`   - list of `%{id: atom, label: string, path: string}`
  """
  attr :current, :atom, required: true
  attr :pages, :list, required: true

  def dashboard_nav(assigns) do
    ~H"""
    <nav class="flex items-center border-b border-border bg-background px-4">
      <span class="text-muted-foreground text-xs mr-4 select-none">midash</span>
      <%= for page <- @pages do %>
        <.link
          navigate={page.path}
          class={[
            "px-3 py-3 text-sm border-b-2 -mb-px transition-colors whitespace-nowrap",
            if(page.id == @current,
              do: "border-foreground text-foreground",
              else: "border-transparent text-muted-foreground hover:text-foreground hover:border-muted"
            )
          ]}
        >
          {page.label}
        </.link>
      <% end %>
    </nav>
    """
  end

  @doc """
  A vertical column. Widgets are stacked inside.

  - `size` - `:small` (narrow sidebar) or `:full` (takes remaining space)
  """
  attr :size, :atom, default: :full
  slot :inner_block, required: true

  def col(assigns) do
    ~H"""
    <div class={col_class(@size)}>
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
    <div class={["mb-4 border border-border bg-card last:mb-0", @class]}>
      <div
        :if={@title}
        class="px-3 py-2 border-b border-border text-xs text-muted-foreground uppercase tracking-widest flex items-center justify-between"
      >
        <span>— {@title}</span>
        <span :if={@on_refresh || @collapsible} class="flex items-center gap-1">
          <button
            :if={@on_refresh}
            phx-click={@on_refresh}
            class="text-muted-foreground hover:text-foreground transition-colors p-0.5"
            title="refresh"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 16 16"
              fill="currentColor"
              class="w-3 h-3"
            >
              <path
                fill-rule="evenodd"
                d="M13.836 2.477a.75.75 0 0 1 .75.75v3.182a.75.75 0 0 1-.75.75h-3.182a.75.75 0 0 1 0-1.5h1.37l-.84-.841a4.5 4.5 0 0 0-7.08.681.75.75 0 0 1-1.3-.75 6 6 0 0 1 9.44-.908l.84.84V3.227a.75.75 0 0 1 .75-.75Zm-.911 7.5A.75.75 0 0 1 13.199 11a6 6 0 0 1-9.44.908l-.84-.84v1.769a.75.75 0 0 1-1.5 0V9.637a.75.75 0 0 1 .75-.75h3.182a.75.75 0 0 1 0 1.5H3.98l.841.841a4.5 4.5 0 0 0 7.08-.681.75.75 0 0 1 1.025-.274Z"
                clip-rule="evenodd"
              />
            </svg>
          </button>
          <button
            :if={@collapsible}
            phx-click={Phoenix.LiveView.JS.toggle(to: "##{@id}-content")}
            class="text-muted-foreground hover:text-foreground transition-colors p-0.5"
            title="collapse"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 16 16"
              fill="currentColor"
              class="w-3 h-3"
            >
              <path
                fill-rule="evenodd"
                d="M4.22 6.22a.75.75 0 0 1 1.06 0L8 8.94l2.72-2.72a.75.75 0 1 1 1.06 1.06l-3.25 3.25a.75.75 0 0 1-1.06 0L4.22 7.28a.75.75 0 0 1 0-1.06Z"
                clip-rule="evenodd"
              />
            </svg>
          </button>
        </span>
      </div>
      <div id={if @id, do: "#{@id}-content"} class="p-3">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  # --- Helpers ---

  defp col_class(:small), do: "w-64 shrink-0"
  defp col_class(:full), do: "flex-1 min-w-0"
  defp col_class(_), do: "flex-1 min-w-0"
end
