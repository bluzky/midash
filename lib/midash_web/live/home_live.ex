defmodule MidashWeb.HomeLive do
  use MidashWeb, :live_view

  alias MidashWeb.Widgets.{ClockWidget, PlaceholderWidget}

  @nav_pages [
    %{id: :home, label: "home", path: "/"},
    %{id: :work, label: "work", path: "/work"},
    %{id: :metrics, label: "metrics", path: "/metrics"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, nav_pages: @nav_pages), layout: {MidashWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_info({:clock_tick, id}, socket) do
    send_update(MidashWeb.Widgets.ClockWidget, id: id)
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.dashboard_layout nav_pages={@nav_pages} current={:home}>
      <.col size={:small}>
        <.widget id="w-home-clock" title="clock" collapsible>
          <.live_component module={ClockWidget} id="home-clock" />
        </.widget>

        <.widget id="w-home-bookmarks" title="bookmarks" collapsible>
          <.live_component module={PlaceholderWidget} id="home-bookmarks"
            message="your bookmarks" />
        </.widget>
      </.col>

      <.col size={:full}>
        <.widget id="w-home-notes" title="notes" collapsible>
          <.live_component module={PlaceholderWidget} id="home-notes"
            message="your notes widget goes here" />
        </.widget>

        <.widget id="w-home-hn" title="hacker news" collapsible>
          <.live_component module={PlaceholderWidget} id="home-hn"
            message="hacker news feed" />
        </.widget>
      </.col>

      <.col size={:small}>
        <.widget id="w-home-markets" title="markets" collapsible>
          <.live_component module={PlaceholderWidget} id="home-markets"
            message="market tickers" />
        </.widget>

        <.widget id="w-home-rss" title="rss" collapsible>
          <.live_component module={PlaceholderWidget} id="home-rss"
            message="rss feeds" />
        </.widget>
      </.col>
    </.dashboard_layout>
    """
  end
end
