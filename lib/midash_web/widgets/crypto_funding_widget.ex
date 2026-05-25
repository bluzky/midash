defmodule MidashWeb.Widgets.CryptoFundingWidget do
  use MidashWeb, :live_component

  alias Midash.Binance
  alias MidashWeb.Widgets.CryptoFundingCard

  @refresh_ms 5 * 60 * 1000

  @impl true
  def mount(socket) do
    {:ok, assign(socket, data: [], loading: true, error: nil)}
  end

  @impl true
  def update(%{action: :fetch}, socket) do
    {:ok, do_fetch(socket)}
  end

  @impl true
  def update(assigns, socket) do
    socket = assign(socket, assigns)

    if connected?(socket) do
      send(self(), {:crypto_funding_tick, socket.assigns.id})
    end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div :if={@loading} class="text-muted-foreground text-sm py-2">fetching...</div>
      <div :if={@error} class="text-destructive text-sm py-2">{@error}</div>
      <div :if={!@loading && !@error} class="space-y-4">
        <%= for item <- @data do %>
          <CryptoFundingCard.card item={item} />
        <% end %>
      </div>
    </div>
    """
  end

  defp do_fetch(socket) do
    symbols = Map.get(socket.assigns, :symbols, ["ETHUSDT", "BTCUSDT"])

    results =
      Enum.map(symbols, fn symbol ->
        with {:ok, premium} <- Binance.fetch_premium_index(symbol),
             {:ok, oi_changes} <- Binance.fetch_open_interest_changes(symbol) do
          Map.merge(premium, %{
            open_interest: oi_changes.open_interest,
            oi_change_1h: oi_changes.change_1h,
            oi_change_4h: oi_changes.change_4h,
            oi_change_24h: oi_changes.change_24h
          })
        else
          {:error, reason} -> {:error, symbol, reason}
        end
      end)

    Process.send_after(self(), {:crypto_funding_tick, socket.assigns.id}, @refresh_ms)

    data = Enum.filter(results, &is_map/1)
    errors = Enum.filter(results, &match?({:error, _, _}, &1))

    if errors != [] and data == [] do
      assign(socket, loading: false, error: "fetch failed")
    else
      assign(socket, data: data, loading: false, error: nil)
    end
  end
end

defmodule MidashWeb.Widgets.CryptoFundingCard do
  use Phoenix.Component

  def card(assigns) do
    ~H"""
    <div class="border border-border rounded p-3 space-y-2">
      <div class="flex items-center justify-between">
        <span class="font-bold text-sm">{short_sym(@item.symbol)}</span>
        <span class="text-muted-foreground text-xs">
          next funding {fmt_countdown(@item.next_funding_time)}
        </span>
      </div>

      <div class="grid grid-cols-2 gap-2">
        <div class="space-y-0.5">
          <div class="text-muted-foreground text-[10px] uppercase tracking-wide">funding rate (8h)</div>
          <div class={["text-base font-mono font-semibold", funding_color(@item.last_funding_rate)]}>
            {fmt_rate(@item.last_funding_rate)}
          </div>
          <div class="text-muted-foreground text-[10px]">
            {fmt_annualized(@item.last_funding_rate)}
          </div>
        </div>

        <div class="space-y-0.5">
          <div class="text-muted-foreground text-[10px] uppercase tracking-wide">open interest</div>
          <div class="text-base font-mono font-semibold text-foreground">
            {fmt_oi(@item.open_interest)}
          </div>
          <div class="text-muted-foreground text-[10px]">{short_sym(@item.symbol)} tokens</div>
        </div>
      </div>

      <div class="grid grid-cols-3 gap-1 pt-1 border-t border-border">
        <div class="space-y-0.5">
          <div class="text-muted-foreground text-[10px]">OI 1h</div>
          <div class={["font-mono text-xs font-semibold", change_color(@item.oi_change_1h)]}>
            {fmt_change(@item.oi_change_1h)}
          </div>
        </div>
        <div class="space-y-0.5">
          <div class="text-muted-foreground text-[10px]">OI 4h</div>
          <div class={["font-mono text-xs font-semibold", change_color(@item.oi_change_4h)]}>
            {fmt_change(@item.oi_change_4h)}
          </div>
        </div>
        <div class="space-y-0.5">
          <div class="text-muted-foreground text-[10px]">OI 24h</div>
          <div class={["font-mono text-xs font-semibold", change_color(@item.oi_change_24h)]}>
            {fmt_change(@item.oi_change_24h)}
          </div>
        </div>
      </div>

      <div class="grid grid-cols-2 gap-2 pt-1 border-t border-border">
        <div class="space-y-0.5">
          <div class="text-muted-foreground text-[10px]">mark price</div>
          <div class="font-mono text-xs text-foreground">${fmt_price(@item.mark_price)}</div>
        </div>
        <div class="space-y-0.5">
          <div class="text-muted-foreground text-[10px]">index price</div>
          <div class="font-mono text-xs text-foreground">${fmt_price(@item.index_price)}</div>
        </div>
      </div>
    </div>
    """
  end

  defp short_sym("ETHUSDT"), do: "ETH"
  defp short_sym("BTCUSDT"), do: "BTC"
  defp short_sym(s), do: String.replace(s, "USDT", "")

  defp fmt_rate(nil), do: "—"
  defp fmt_rate(r) do
    sign = if r >= 0, do: "+", else: ""
    "#{sign}#{:erlang.float_to_binary(r * 100, decimals: 4)}%"
  end

  defp fmt_annualized(nil), do: "—"
  defp fmt_annualized(r) do
    daily = r * 3 * 100
    sign = if daily >= 0, do: "+", else: ""
    "#{sign}#{:erlang.float_to_binary(daily, decimals: 4)}% 24h"
  end

  defp funding_color(nil), do: "text-muted-foreground"
  defp funding_color(r) when r > 0.00004, do: "text-green-400"
  defp funding_color(r) when r < -0.00004, do: "text-red-400"
  defp funding_color(_), do: "text-white"

  defp fmt_oi(nil), do: "—"
  defp fmt_oi(v) when v >= 1_000_000, do: "#{:erlang.float_to_binary(v / 1_000_000, decimals: 2)}M"
  defp fmt_oi(v) when v >= 1_000, do: "#{:erlang.float_to_binary(v / 1_000, decimals: 1)}K"
  defp fmt_oi(v), do: :erlang.float_to_binary(v, decimals: 0)

  defp fmt_price(nil), do: "—"
  defp fmt_price(p) when p >= 1000 do
    p |> :erlang.float_to_binary(decimals: 0)
    |> String.reverse() |> String.graphemes()
    |> Enum.chunk_every(3) |> Enum.join(",") |> String.reverse()
  end
  defp fmt_price(p), do: :erlang.float_to_binary(p, decimals: 2)

  defp fmt_change(nil), do: "—"
  defp fmt_change(v) when v >= 0, do: "+#{:erlang.float_to_binary(Float.round(v, 2), decimals: 2)}%"
  defp fmt_change(v), do: "#{:erlang.float_to_binary(Float.round(v, 2), decimals: 2)}%"

  defp change_color(nil), do: "text-muted-foreground"
  defp change_color(v) when v > 0, do: "text-green-400"
  defp change_color(v) when v < 0, do: "text-red-400"
  defp change_color(_), do: "text-muted-foreground"

  defp fmt_countdown(nil), do: "—"
  defp fmt_countdown(ms) when is_integer(ms) do
    now_ms = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
    diff_s = div(ms - now_ms, 1000)

    cond do
      diff_s <= 0 -> "now"
      diff_s < 3600 -> "#{div(diff_s, 60)}m #{rem(diff_s, 60)}s"
      true -> "#{div(diff_s, 3600)}h #{div(rem(diff_s, 3600), 60)}m"
    end
  end
end
