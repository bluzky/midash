defmodule MidashWeb.CryptoLive do
  use MidashWeb, :live_view

  alias MidashWeb.Widgets.{CryptoFundingWidget, MultiSymbolChartWidget}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket, layout: {MidashWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_info({:crypto_funding_tick, id}, socket) do
    send_update(CryptoFundingWidget, id: id, action: :fetch)
    {:noreply, socket}
  end

  def handle_info({:multi_chart_tick, id}, socket) do
    send_update(MultiSymbolChartWidget, id: id, action: :fetch)
    {:noreply, socket}
  end

  def handle_info({:multi_chart_countdown, id}, socket) do
    send_update(MultiSymbolChartWidget, id: id, action: :countdown)
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.dashboard_layout current={MidashWeb.Nav.current_from_module(__MODULE__)}>
      <.col span={4}>
        <.widget id="w-crypto-main-charts" title="ETH / BTC" collapsible>
          <.live_component
            module={MultiSymbolChartWidget}
            id="crypto-main-charts"
            symbols={["ETHUSDT", "BTCUSDT"]}
          />
        </.widget>
      </.col>

      <.col span={4}>
        <.widget id="w-crypto-alt-charts" title="others" collapsible>
          <.live_component
            module={MultiSymbolChartWidget}
            id="crypto-alt-charts"
            symbols={["ZECUSDC", "HYPEUSDT"]}
          />
        </.widget>
      </.col>

      <.col span={4}>
        <.widget id="w-crypto-funding" title="funding rate & open interest" collapsible>
          <.live_component module={CryptoFundingWidget} id="crypto-funding" />
        </.widget>

      </.col>
    </.dashboard_layout>
    """
  end
end
