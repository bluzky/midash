defmodule MidashWeb.Widgets.MultiSymbolChartWidget do
  use MidashWeb, :live_component

  alias Midash.Binance

  @refresh_ms 60_000
  @visible_candles 72
  @bb_warmup 19
  @chart_height 150
  @intervals [{"15m", "15m"}, {"1h", "1h"}, {"4h", "4h"}, {"1d", "24h"}]

  @impl true
  def mount(socket) do
    {:ok,
     assign(socket,
       interval: "1h",
       charts: %{},
       intervals: @intervals,
       next_refresh_ms: nil
     )}
  end

  @impl true
  def update(%{action: :fetch}, socket) do
    {:ok, do_fetch_all(socket)}
  end

  @impl true
  def update(%{action: :countdown}, socket) do
    remaining = max((socket.assigns.next_refresh_ms || 0) - 1000, 0)
    schedule_countdown(socket.assigns.id, remaining)
    {:ok, assign(socket, next_refresh_ms: remaining)}
  end

  @impl true
  def update(assigns, socket) do
    socket = assign(socket, assigns)

    if connected?(socket) do
      send(self(), {:multi_chart_tick, socket.assigns.id})
    end

    {:ok, socket}
  end

  @impl true
  def handle_event("set_interval", %{"interval" => interval}, socket) do
    valid = Enum.map(@intervals, &elem(&1, 0))

    if interval in valid do
      {:noreply, socket |> assign(interval: interval) |> do_fetch_all()}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="flex items-center justify-between mb-3">
        <div class="text-muted-foreground text-xs font-mono">
          <%= if @next_refresh_ms do %>
            refresh in {countdown_str(@next_refresh_ms)}
          <% end %>
        </div>
        <div class="flex items-center gap-1">
          <%= for {value, label} <- @intervals do %>
            <button
              phx-click="set_interval"
              phx-value-interval={value}
              phx-target={@myself}
              class={[
                "px-2 py-0.5 text-xs font-mono rounded",
                @interval == value && "bg-border text-foreground",
                @interval != value && "text-muted-foreground hover:text-foreground"
              ]}
            >
              {label}
            </button>
          <% end %>
        </div>
      </div>

      <%= for symbol <- @symbols do %>
        <% chart = Map.get(@charts, symbol, %{loading: true, error: nil, candles: [], svg: "", ticker: nil}) %>
        <div class="mb-5 last:mb-0">
          <div class="flex items-baseline gap-2">
            <span class="text-xs font-mono text-muted-foreground">{symbol}</span>
            <%= if chart[:ticker] do %>
              <span class="text-sm font-bold tabular-nums">
                ${price_str(chart.ticker.last_price)}
              </span>
              <span class={["text-xs font-mono", pct_class(chart.ticker.price_change_percent)]}>
                {pct_str(chart.ticker.price_change_percent)}
              </span>
            <% end %>
          </div>

          <div :if={chart[:loading]} class="text-muted-foreground text-xs py-3 text-center">
            fetching...
          </div>
          <div :if={chart[:error]} class="text-destructive text-xs py-2">{chart.error}</div>
          <div :if={!chart[:loading] && !chart[:error] && chart[:svg] != ""}>
            {Phoenix.HTML.raw(chart.svg)}
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp do_fetch_all(socket) do
    symbols = Map.get(socket.assigns, :symbols, [])
    interval = socket.assigns.interval

    charts =
      Enum.reduce(symbols, socket.assigns.charts, fn symbol, acc ->
        # mark loading while refetching
        Map.put(acc, symbol, Map.merge(Map.get(acc, symbol, %{}), %{loading: true, error: nil}))
      end)

    socket = assign(socket, charts: charts)

    charts =
      Enum.reduce(symbols, socket.assigns.charts, fn symbol, acc ->
        Map.put(acc, symbol, fetch_symbol(symbol, interval))
      end)

    Process.send_after(self(), {:multi_chart_tick, socket.assigns.id}, @refresh_ms)
    schedule_countdown(socket.assigns.id, @refresh_ms)

    assign(socket, charts: charts, next_refresh_ms: @refresh_ms)
  end

  defp fetch_symbol(symbol, interval) do
    klines_result = Binance.fetch_klines(symbol, interval, @visible_candles + @bb_warmup)
    ticker_result = Binance.fetch_ticker_24h(symbol)

    case klines_result do
      {:ok, all_candles} ->
        ticker =
          case ticker_result do
            {:ok, t} -> t
            _ -> nil
          end

        visible = Enum.take(all_candles, -@visible_candles)

        %{
          candles: visible,
          svg: build_svg_string(all_candles, @visible_candles),
          ticker: ticker,
          loading: false,
          error: nil
        }

      {:error, reason} ->
        %{candles: [], svg: "", ticker: nil, loading: false, error: "failed: #{reason}"}
    end
  end

  defp build_svg_string([], _visible), do: ""

  defp build_svg_string(all_candles, visible_count) do
    width = 600
    height = @chart_height
    pad_top = 6
    pad_bottom = 6
    y_axis_w = 58
    chart_w = width - y_axis_w
    chart_h = height - pad_top - pad_bottom

    bb_all = bollinger_bands(all_candles, 20, 2.0)
    visible_candles = Enum.take(all_candles, -visible_count)
    visible_bb = Enum.take(bb_all, -visible_count)

    bb_highs = Enum.map(visible_bb, & &1.upper)
    bb_lows = Enum.map(visible_bb, & &1.lower)
    candle_highs = Enum.map(visible_candles, & &1.high)
    candle_lows = Enum.map(visible_candles, & &1.low)

    min_p = Enum.min(candle_lows ++ bb_lows)
    max_p = Enum.max(candle_highs ++ bb_highs)
    range = max(max_p - min_p, 1.0)

    n = visible_count
    slot_w = chart_w / n
    body_w = max(slot_w * 0.6, 1.0)
    gap = (slot_w - body_w) / 2

    price_to_y = fn p -> pad_top + (max_p - p) / range * chart_h end

    indexed_bb = Enum.with_index(visible_bb, fn b, i -> Map.put(b, :index, i) end)
    bollinger_svg = build_bollinger(indexed_bb, slot_w, price_to_y)

    grid_lines =
      0..4
      |> Enum.map(fn i ->
        price = min_p + range * (4 - i) / 4
        y = Float.round(price_to_y.(price), 1)
        label = "$#{price_str(price)}"
        label_y = max(y + 3.5, pad_top + 3.5)

        "<line x1=\"0\" y1=\"#{y}\" x2=\"#{chart_w}\" y2=\"#{y}\" stroke=\"currentColor\" stroke-width=\"1\"/>" <>
          "<text x=\"#{chart_w + 4}\" y=\"#{label_y}\" font-size=\"9\" fill=\"#6b7280\" font-family=\"monospace\">#{label}</text>"
      end)
      |> Enum.join("\n")

    candle_shapes =
      visible_candles
      |> Enum.with_index()
      |> Enum.map(fn {c, i} ->
        color = if c.close >= c.open, do: "#22c55e", else: "#ef4444"
        cx = Float.round(i * slot_w + slot_w / 2, 1)
        bx = Float.round(i * slot_w + gap, 1)
        by = Float.round(min(price_to_y.(c.open), price_to_y.(c.close)), 1)
        bh = Float.round(max(abs(price_to_y.(c.close) - price_to_y.(c.open)), 1.0), 1)
        hy = Float.round(price_to_y.(c.high), 1)
        ly = Float.round(price_to_y.(c.low), 1)
        bwr = Float.round(body_w, 1)

        "<line x1=\"#{cx}\" y1=\"#{hy}\" x2=\"#{cx}\" y2=\"#{ly}\" stroke=\"#{color}\" stroke-width=\"1\" opacity=\"0.7\"/>" <>
          "<rect x=\"#{bx}\" y=\"#{by}\" width=\"#{bwr}\" height=\"#{bh}\" fill=\"#{color}\" opacity=\"0.9\"/>"
      end)
      |> Enum.join("\n")

    "<svg viewBox=\"0 0 #{width} #{height}\" class=\"w-full\" style=\"height: #{height}px; color: hsl(var(--border))\" xmlns=\"http://www.w3.org/2000/svg\">" <>
      grid_lines <>
      bollinger_svg <>
      candle_shapes <>
      "</svg>"
  end

  defp bollinger_bands(candles, period, mult) do
    closes = Enum.map(candles, & &1.close)

    closes
    |> Enum.with_index()
    |> Enum.flat_map(fn {_close, i} ->
      if i < period - 1 do
        []
      else
        window = Enum.slice(closes, (i - period + 1)..i)
        mean = Enum.sum(window) / period
        variance = Enum.sum(Enum.map(window, fn p -> (p - mean) * (p - mean) end)) / period
        stddev = :math.sqrt(variance)
        [%{index: i, upper: mean + mult * stddev, middle: mean, lower: mean - mult * stddev}]
      end
    end)
  end

  defp build_bollinger([], _slot_w, _price_to_y), do: ""

  defp build_bollinger(bands, slot_w, price_to_y) do
    cx_of = fn i -> i * slot_w + slot_w / 2 end
    pt = fn b, key -> "#{Float.round(cx_of.(b.index), 1)},#{Float.round(price_to_y.(Map.get(b, key)), 1)}" end

    upper_pts = bands |> Enum.map(&pt.(&1, :upper)) |> Enum.join(" ")
    lower_pts_rev = bands |> Enum.reverse() |> Enum.map(&pt.(&1, :lower)) |> Enum.join(" ")
    lower_pts_fwd = bands |> Enum.map(&pt.(&1, :lower)) |> Enum.join(" ")
    mid_pts = bands |> Enum.map(&pt.(&1, :middle)) |> Enum.join(" ")

    "<polygon points=\"#{upper_pts} #{lower_pts_rev}\" fill=\"#a855f7\" opacity=\"0.06\"/>" <>
      "<polyline points=\"#{upper_pts}\" fill=\"none\" stroke=\"#f97316\" stroke-width=\"1\" opacity=\"0.6\"/>" <>
      "<polyline points=\"#{lower_pts_fwd}\" fill=\"none\" stroke=\"#a855f7\" stroke-width=\"1\" opacity=\"0.6\"/>" <>
      "<polyline points=\"#{mid_pts}\" fill=\"none\" stroke=\"#ec4899\" stroke-width=\"1\" opacity=\"0.6\" stroke-dasharray=\"3,2\"/>"
  end

  defp schedule_countdown(id, remaining_ms) when remaining_ms > 1000 do
    Process.send_after(self(), {:multi_chart_countdown, id}, 1000)
  end

  defp schedule_countdown(_id, _), do: :ok

  defp countdown_str(ms) when is_integer(ms) and ms > 0 do
    s = div(ms, 1000)
    "#{div(s, 60)}:#{String.pad_leading(to_string(rem(s, 60)), 2, "0")}"
  end

  defp countdown_str(_), do: "0:00"

  defp price_str(nil), do: "—"

  defp price_str(p) when p >= 1000 do
    p
    |> :erlang.float_to_binary(decimals: 0)
    |> String.reverse()
    |> String.graphemes()
    |> Enum.chunk_every(3)
    |> Enum.join(",")
    |> String.reverse()
  end

  defp price_str(p), do: :erlang.float_to_binary(p, decimals: 2)

  defp pct_str(nil), do: "—"
  defp pct_str(p) when p >= 0, do: "+#{Float.round(p, 2)}%"
  defp pct_str(p), do: "#{Float.round(p, 2)}%"

  defp pct_class(nil), do: "text-muted-foreground"
  defp pct_class(p) when p >= 0, do: "text-green-500"
  defp pct_class(_), do: "text-red-500"

  defp time_str(nil), do: ""

  defp time_str(ms) when is_integer(ms) do
    ms
    |> div(1000)
    |> DateTime.from_unix!()
    |> Calendar.strftime("%m/%d %H:%M")
  end
end
