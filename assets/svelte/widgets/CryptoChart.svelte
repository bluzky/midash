<script>
  import { onMount, untrack } from 'svelte'
  import { createChart, CandlestickSeries as CandleSeries, HistogramSeries as VolSeries, LineStyle } from 'lightweight-charts'
  import { ToggleGroup } from 'bits-ui'
  import { get } from '../lib/api.js'
  import { bollingerBands, ema } from '../lib/indicators/index.js'
  import Spinner from '../components/Spinner.svelte'
  import { baseChartOptions } from '../lib/chart-theme.js'

  let { symbol = 'ETHUSDT', indicators = [bollingerBands(), ema({ period: 9, color: '#EAB308' }), ema({ period: 21, color: '#EC4899' })] } = $props()

  const INTERVALS = [
    { key: '15m', label: '15m' },
    { key: '1h', label: '1h' },
    { key: '4h', label: '4h' },
    { key: '1d', label: '1d' },
  ]
  const CANDLE_H = 260
  const VOLUME_H = 60
  const CHART_H = CANDLE_H + VOLUME_H
  const CANDLE_PX = 8  // px per candle — matches default lightweight-charts bar spacing

  const warmup = Math.max(0, ...indicators.map((ind) => ind.warmup ?? 0))

  let containerWidth = $state(0)
  let visible = $derived(containerWidth > 0 ? Math.floor(containerWidth / CANDLE_PX) : 0)

  let interval = $state('15m')
  let chartData = $state(null)
  let loading = $state(true)
  let countdown = $state(60)

  async function fetchAll() {
    if (visible === 0) return
    loading = true
    try {
      const [kRes, dayRes] = await Promise.all([
        get(`/api/crypto/klines?symbol=${symbol}&interval=${interval}&limit=${visible + warmup}`),
        get(`/api/crypto/klines?symbol=${symbol}&interval=1d&limit=2`),
      ])
      const allMapped = kRes.data.map((c) => ({
        time: Math.floor(c.open_time / 1000),
        open: c.open,
        high: c.high,
        low: c.low,
        close: c.close,
      }))
      const prevDay = dayRes.data[0]
      chartData = {
        candles: allMapped.slice(-visible),
        volume: kRes.data.slice(-visible).map((c) => ({
          time: Math.floor(c.open_time / 1000),
          value: c.volume,
          color: c.close >= c.open ? '#16a34a66' : '#dc262666',
        })),
        indicatorData: indicators.map((ind) => ind.compute(allMapped).slice(-visible)),
        pdHigh: prevDay?.high ?? null,
        pdLow: prevDay?.low ?? null,
        last: kRes.data.at(-1),
        error: null,
      }
    } catch (e) {
      chartData = { candles: [], volume: [], indicatorData: [], pdHigh: null, pdLow: null, last: null, error: e.message }
    }
    loading = false
    countdown = 60
  }

  export async function refresh() { await fetchAll() }

  // Re-fetch when container width changes (initial mount + window resize).
  // Debounced so rapid resize events don't trigger many API calls.
  // untrack(fetchAll) prevents interval/$state reads inside fetchAll from
  // becoming dependencies of this effect and causing extra re-runs.
  $effect(() => {
    const v = visible
    if (v === 0) return
    const t = setTimeout(() => untrack(fetchAll), 150)
    return () => clearTimeout(t)
  })

  onMount(() => {
    const refreshInterval = setInterval(fetchAll, 60_000)
    const countdownInterval = setInterval(() => { if (countdown > 0) countdown-- }, 1000)
    return () => { clearInterval(refreshInterval); clearInterval(countdownInterval) }
  })

  const PD_LINE = { color: '#2563EB', lineWidth: 1, lineStyle: LineStyle.Dashed, axisLabelVisible: true }

  function setPriceLines(series, pdHigh, pdLow) {
    const high = pdHigh != null ? series.createPriceLine({ ...PD_LINE, price: pdHigh, title: 'PDH' }) : null
    const low  = pdLow  != null ? series.createPriceLine({ ...PD_LINE, price: pdLow,  title: 'PDL' }) : null
    return { high, low }
  }

  function candleChart(node, params) {
    const chart = createChart(node, { ...baseChartOptions, width: node.clientWidth, height: CHART_H })

    const candleSeries = chart.addSeries(CandleSeries, {
      upColor: '#16a34a',
      downColor: '#dc2626',
      borderVisible: false,
      wickUpColor: '#16a34a',
      wickDownColor: '#dc2626',
    })

    const mounted = indicators.map((ind) => ind.mount(chart))

    const volSeries = chart.addSeries(VolSeries, {
      priceScaleId: 'volume',
      priceFormat: { type: 'volume' },
    })
    volSeries.priceScale().applyOptions({ scaleMargins: { top: 0.75, bottom: 0 } })

    candleSeries.setData(params.candles)
    volSeries.setData(params.volume)
    mounted.forEach((m, i) => m.update(params.indicatorData[i] ?? []))

    let pdLines = setPriceLines(candleSeries, params.pdHigh, params.pdLow)

    const ro = new ResizeObserver(() => chart.resize(node.clientWidth, CHART_H))
    ro.observe(node)

    return {
      update(p) {
        candleSeries.setData(p.candles)
        volSeries.setData(p.volume)
        mounted.forEach((m, i) => m.update(p.indicatorData[i] ?? []))

        if (pdLines.high) candleSeries.removePriceLine(pdLines.high)
        if (pdLines.low)  candleSeries.removePriceLine(pdLines.low)
        pdLines = setPriceLines(candleSeries, p.pdHigh, p.pdLow)
      },
      destroy() {
        mounted.forEach((m) => m.destroy())
        ro.disconnect()
        chart.remove()
      },
    }
  }
</script>

<div class="space-y-1" bind:clientWidth={containerWidth}>
  <div class="flex items-center gap-1 mb-3">
    <ToggleGroup.Root
      type="single"
      value={interval}
      onValueChange={(v) => { if (v) { interval = v; fetchAll() } }}
      class="flex gap-1"
    >
      {#each INTERVALS as iv}
        <ToggleGroup.Item
          value={iv.key}
          class="px-2 py-0.5 text-xs rounded-md border transition-colors outline-none
            data-[state=on]:border-primary data-[state=on]:text-primary data-[state=on]:bg-primary/10
            data-[state=off]:border-border data-[state=off]:text-muted-foreground hover:text-foreground hover:bg-secondary"
        >
          {iv.label}
        </ToggleGroup.Item>
      {/each}
    </ToggleGroup.Root>
    <span class="ml-auto text-xs text-muted-foreground tabular-nums">refresh in {countdown}s</span>
  </div>

  {#if loading}
    <Spinner />
  {:else if chartData?.error}
    <div class="text-destructive text-xs">{chartData.error}</div>
  {:else if chartData?.candles?.length}
    <div use:candleChart={{ candles: chartData.candles, volume: chartData.volume, indicatorData: chartData.indicatorData, pdHigh: chartData.pdHigh, pdLow: chartData.pdLow }}></div>
    {#if chartData.last}
      {@const last = chartData.last}
      <div class="flex gap-4 text-xs text-muted-foreground font-mono mt-1">
        <span>O {last.open.toFixed(2)}</span>
        <span>H {last.high.toFixed(2)}</span>
        <span>L {last.low.toFixed(2)}</span>
        <span class={last.close >= last.open ? 'text-success' : 'text-destructive'}>C {last.close.toFixed(2)}</span>
      </div>
    {/if}
  {/if}
</div>
