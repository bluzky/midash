defmodule MidashWeb.MetricsLive do
  use MidashWeb, :live_view

  alias MidashWeb.Widgets.PlaceholderWidget

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
  def render(assigns) do
    ~H"""
    <.dashboard_layout nav_pages={@nav_pages} current={:metrics}>
      <.col size={:small}>
        <.widget title="status">
          <.live_component module={PlaceholderWidget} id="metrics-status"
            message="service status" />
        </.widget>
      </.col>

      <.col size={:full}>
        <.widget title="stats">
          <.live_component module={PlaceholderWidget} id="metrics-stats"
            message="your metrics widget goes here" />
        </.widget>
      </.col>

      <.col size={:small}>
        <.widget title="alerts">
          <.live_component module={PlaceholderWidget} id="metrics-alerts"
            message="alerts" />
        </.widget>
      </.col>
    </.dashboard_layout>
    """
  end
end
