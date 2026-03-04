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
    <div class="min-h-screen bg-[#0d0d0d] text-gray-300 font-mono">
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
    <nav class="flex items-center border-b border-gray-800 bg-[#0d0d0d] px-4">
      <span class="text-gray-600 text-xs mr-4 select-none">midash</span>
      <%= for page <- @pages do %>
        <.link
          navigate={page.path}
          class={[
            "px-3 py-3 text-sm border-b-2 -mb-px transition-colors whitespace-nowrap",
            if(page.id == @current,
              do: "border-gray-300 text-gray-100",
              else: "border-transparent text-gray-500 hover:text-gray-300 hover:border-gray-600"
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

  - `title` - optional string shown in header
  """
  attr :title, :string, default: nil
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def widget(assigns) do
    ~H"""
    <div class={["mb-4 border border-gray-800 bg-[#141414] last:mb-0", @class]}>
      <div
        :if={@title}
        class="px-3 py-2 border-b border-gray-800 text-xs text-gray-500 uppercase tracking-widest"
      >
        — {@title}
      </div>
      <div class="p-3">
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
