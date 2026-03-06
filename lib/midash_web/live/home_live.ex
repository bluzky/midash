defmodule MidashWeb.HomeLive do
  use MidashWeb, :live_view

  alias MidashWeb.Widgets.{WorldClockWidget, PlaceholderWidget}

  @world_clocks [
    %{label: "Phoenix", tz: "America/Phoenix"},
    %{label: "Singapore", tz: "Asia/Singapore"},
    %{label: "Tokyo", tz: "Asia/Tokyo"}
  ]

  @nav_pages [
    %{id: :home, label: "home", path: "/"},
    %{id: :work, label: "work", path: "/work"},
    %{id: :monitor, label: "monitor", path: "/monitor"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, nav_pages: @nav_pages, world_clocks: @world_clocks),
     layout: {MidashWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_info({:world_clock_tick, id}, socket) do
    send_update(WorldClockWidget, id: id)
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.dashboard_layout nav_pages={@nav_pages} current={:home}>
      <.col span={3}>
        <.widget id="w-home-world-clock" title="world clock" collapsible>
          <.live_component module={WorldClockWidget} id="home-world-clock" clocks={@world_clocks} />
        </.widget>

        <.widget id="w-home-bookmarks" title="bookmarks" collapsible>
          <.live_component module={PlaceholderWidget} id="home-bookmarks" message="your bookmarks" />
        </.widget>
      </.col>

      <.col span={6}>
        <.widget id="w-home-notes" title="notes" collapsible>
          <.live_component
            module={PlaceholderWidget}
            id="home-notes"
            message="your notes widget goes here"
          />
        </.widget>

        <.widget id="w-home-hn" title="hacker news" collapsible>
          <.live_component module={PlaceholderWidget} id="home-hn" message="hacker news feed" />
        </.widget>
      </.col>

      <.col span={3}>
        <.widget id="w-home-markets" title="markets" collapsible>
          <.live_component module={PlaceholderWidget} id="home-markets" message="market tickers" />
        </.widget>

        <.widget id="w-home-rss" title="rss" collapsible>
          <.live_component module={PlaceholderWidget} id="home-rss" message="rss feeds" />
        </.widget>
      </.col>
    </.dashboard_layout>
    """
  end
end
