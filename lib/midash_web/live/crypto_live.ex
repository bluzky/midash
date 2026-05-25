defmodule MidashWeb.CryptoLive do
  use MidashWeb, :live_view

  alias MidashWeb.Widgets.{BinanceFuturesChartWidget, CryptoFundingWidget}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket, layout: {MidashWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_info({:futures_chart_tick, id}, socket) do
    send_update(BinanceFuturesChartWidget, id: id, action: :fetch)
    {:noreply, socket}
  end

  def handle_info({:futures_countdown_tick, id}, socket) do
    send_update(BinanceFuturesChartWidget, id: id, action: :countdown)
    {:noreply, socket}
  end

  def handle_info({:crypto_funding_tick, id}, socket) do
    send_update(CryptoFundingWidget, id: id, action: :fetch)
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.dashboard_layout current={MidashWeb.Nav.current_from_module(__MODULE__)}>
      <.col span={6}>
        <.widget id="w-crypto-eth-chart" title="ETH/USDT perpetual" collapsible>
          <.live_component module={BinanceFuturesChartWidget} id="crypto-eth-chart" symbol="ETHUSDT" />
        </.widget>

        <.widget id="w-crypto-btc-chart" title="BTC/USDT perpetual" collapsible>
          <.live_component module={BinanceFuturesChartWidget} id="crypto-btc-chart" symbol="BTCUSDT" />
        </.widget>
      </.col>

      <.col span={6}>
        <.widget id="w-crypto-funding" title="funding rate & open interest" collapsible>
          <.live_component module={CryptoFundingWidget} id="crypto-funding" />
        </.widget>
      </.col>
    </.dashboard_layout>
    """
  end
end
