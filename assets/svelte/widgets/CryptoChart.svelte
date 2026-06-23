<script>
  import { onMount, untrack } from 'svelte'
  import { createChart, CandlestickSeries as CandleSeries, HistogramSeries as VolSeries, LineStyle } from 'lightweight-charts'
  import { DropdownMenu, ToggleGroup } from 'bits-ui'
  import { Check, Crosshair, Settings2 } from '@lucide/svelte'
  import { get } from '../lib/api.js'
  import { bollingerBands, ema, macd, marketStructure, orderBlock, superTrend } from '../lib/indicators/index.js'
  import Spinner from '../components/Spinner.svelte'
  import { baseChartOptions } from '../lib/chart-theme.js'

  let { symbol = 'ETHUSDT', indicators = [bollingerBands(), ema({ period: 9, color: '#EAB308' }), ema({ period: 21, color: '#EC4899' }), superTrend(), marketStructure(), orderBlock(), macd()] } = $props()

  const INTERVALS = [
    { key: '5m', label: '5m' },
    { key: '15m', label: '15m' },
    { key: '1h', label: '1h' },
    { key: '4h', label: '4h' },
    { key: '1d', label: '1d' },
  ]
  const CANDLE_H = 260
  const VOLUME_H = 60
  const CANDLE_PX = 6
  const RR_OPTIONS = [1, 2, 3]
  const MIN_BARS = 120
  const MAX_BARS = 1000

  const warmup = Math.max(0, ...indicators.map((ind) => ind.warmup ?? 0))

  let chartH = $derived(
    CANDLE_H + indicators.filter((ind) => ind.panel).reduce((s, ind) => s + ind.panel.height, 0) + VOLUME_H
  )

  let containerWidth = $state(0)
  let visible = $derived(containerWidth > 0 ? Math.floor(containerWidth / CANDLE_PX) : 0)

  let interval = $state('15m')
  let loadedBars = $state(0)
  let enabled = $state(indicators.map((ind) => ind.name !== 'SUPER'))
  let hoveredTime = $state(null)
  let chartData = $state(null)
  let loading = $state(true)

  // Measurement tool
  let measureMode = $state(false)
  let rrRatio = $state(2)
  let measurement = $state(null)  // { entryPrice, slPrice, tpPrice }
  let dragging = $state(false)
  let overlay = $state(null)      // { entryY, slY, tpY }
  let chartInstance = null        // { chart, candleSeries } — plain ref, not reactive

  function computeOverlay() {
    if (!measurement || !chartInstance) { overlay = null; return }
    const { candleSeries } = chartInstance
    const entryY = candleSeries.priceToCoordinate(measurement.entryPrice)
    if (entryY == null) { overlay = null; return }
    const rawSlY = candleSeries.priceToCoordinate(measurement.slPrice)
    const rawTpY = candleSeries.priceToCoordinate(measurement.tpPrice)
    // Clamp off-screen levels to chart edge (higher price = lower Y in chart coords)
    const slY = rawSlY ?? (measurement.slPrice > measurement.entryPrice ? 0 : chartH)
    const tpY = rawTpY ?? (measurement.tpPrice > measurement.entryPrice ? 0 : chartH)
    overlay = { entryY, slY, tpY }
  }

  function handleMeasureDown(e) {
    if (!chartInstance) return
    e.preventDefault()
    const price = chartInstance.candleSeries.coordinateToPrice(e.offsetY)
    if (price == null) return
    measurement = { entryPrice: price, slPrice: price, tpPrice: price }
    dragging = true
  }

  function handleMeasureMove(e) {
    if (!dragging || !chartInstance) return
    const price = chartInstance.candleSeries.coordinateToPrice(e.offsetY)
    if (price == null) return
    const risk = measurement.entryPrice - price
    measurement = { entryPrice: measurement.entryPrice, slPrice: price, tpPrice: measurement.entryPrice + risk * rrRatio }
    computeOverlay()
  }

  function handleMeasureUp() { dragging = false }

  function setRR(ratio) {
    rrRatio = ratio
    if (measurement) {
      const risk = measurement.entryPrice - measurement.slPrice
      measurement = { ...measurement, tpPrice: measurement.entryPrice + risk * ratio }
      computeOverlay()
    }
  }

  function resetLoadedBars() {
    loadedBars = Math.min(MAX_BARS, Math.max(MIN_BARS, visible || MIN_BARS))
  }

  function changeInterval(v) {
    if (!v || v === interval) return
    interval = v
    resetLoadedBars()
    chartData = null
    hoveredTime = null
    measurement = null
    overlay = null
    fetchData('full')
  }

  let emaIndexes = $derived(indicators
    .map((ind, i) => ind.name.startsWith('EMA ') ? i : null)
    .filter((i) => i !== null))
  let menuIndicators = $derived([
    ...(emaIndexes.length ? [{ type: 'ema', name: 'EMA', color: indicators[emaIndexes[0]]?.color }] : []),
    ...indicators.map((ind, i) => ({ type: 'single', ind, i })).filter((item) => !item.ind.name.startsWith('EMA ')),
  ])

  function menuItemEnabled(item) {
    return item.type === 'ema' ? emaIndexes.some((i) => enabled[i]) : enabled[item.i]
  }

  function toggleMenuItem(item) {
    if (item.type === 'ema') {
      const next = !emaIndexes.some((i) => enabled[i])
      emaIndexes.forEach((i) => (enabled[i] = next))
    } else {
      enabled[item.i] = !enabled[item.i]
    }
  }

  function buildChartData(kRes, dayRes, mode) {
    const allMapped = kRes.data.map((c) => ({
      time: Math.floor(c.open_time / 1000),
      open: c.open,
      high: c.high,
      low: c.low,
      close: c.close,
    }))
    const prevDay = dayRes.data[0]
    return {
      mode,
      candles: allMapped.slice(-loadedBars),
      volume: kRes.data.slice(-loadedBars).map((c) => ({
        time: Math.floor(c.open_time / 1000),
        value: c.volume,
        color: c.close >= c.open ? '#16a34a66' : '#dc262666',
      })),
      indicatorData: indicators.map((ind) => ind.compute(allMapped).slice(-loadedBars)),
      pdHigh: prevDay?.high ?? null,
      pdLow: prevDay?.low ?? null,
      last: kRes.data.at(-1),
      error: null,
    }
  }

  async function fetchData(mode = 'full') {
    if (visible === 0 || loadedBars === 0) return
    if (mode === 'full') loading = true
    try {
      const limit = Math.min(MAX_BARS + warmup, loadedBars + warmup)
      const [kRes, dayRes] = await Promise.all([
        get(`/api/crypto/klines?symbol=${symbol}&interval=${interval}&limit=${limit}`),
        get(`/api/crypto/klines?symbol=${symbol}&interval=1d&limit=2`),
      ])
      chartData = buildChartData(kRes, dayRes, mode)
    } catch (e) {
      if (mode === 'full') {
        chartData = { mode: 'full', candles: [], volume: [], indicatorData: [], pdHigh: null, pdLow: null, last: null, error: e.message }
      }
    }
    loading = false
  }

  export async function refresh() { await fetchData('full') }

  $effect(() => {
    const v = visible
    if (v === 0) return
    const target = Math.min(MAX_BARS, Math.max(MIN_BARS, v))
    if (untrack(() => loadedBars) < target) loadedBars = target
    const t = setTimeout(() => untrack(() => fetchData('full')), 150)
    return () => clearTimeout(t)
  })

  onMount(() => {
    const refreshInterval = setInterval(() => fetchData('incremental'), 60_000)
    return () => clearInterval(refreshInterval)
  })

  const PD_LINE = { color: '#2563EB', lineWidth: 1, lineStyle: LineStyle.Dashed, axisLabelVisible: true }

  function setPriceLines(series, pdHigh, pdLow) {
    const high = pdHigh != null ? series.createPriceLine({ ...PD_LINE, price: pdHigh, title: 'PDH' }) : null
    const low  = pdLow  != null ? series.createPriceLine({ ...PD_LINE, price: pdLow,  title: 'PDL' }) : null
    return { high, low }
  }

  function candleChart(node, params) {
    const panelInds = indicators.filter((ind) => ind.panel)
    const panelH = panelInds.reduce((s, ind) => s + ind.panel.height, 0)
    const h = CANDLE_H + panelH + VOLUME_H

    const chart = createChart(node, {
      ...baseChartOptions,
      width: node.clientWidth,
      height: h,
      timeScale: { ...baseChartOptions.timeScale, barSpacing: CANDLE_PX, rightOffset: 0 },
    })

    const candleSeries = chart.addSeries(CandleSeries, {
      upColor: '#ffffff',
      downColor: '#172554',
      borderVisible: true,
      borderUpColor: '#172554',
      borderDownColor: '#172554',
      wickUpColor: '#172554',
      wickDownColor: '#172554',
    })

    candleSeries.priceScale().applyOptions({
      scaleMargins: { top: 0, bottom: (panelH + VOLUME_H) / h },
    })

    const mounted = indicators.map((ind) => {
      if (!ind.panel) return ind.mount(chart)
      const panelIndex = panelInds.indexOf(ind)
      const topOffset    = CANDLE_H + panelInds.slice(0, panelIndex).reduce((s, p) => s + p.panel.height, 0)
      const bottomOffset = VOLUME_H + panelInds.slice(panelIndex + 1).reduce((s, p) => s + p.panel.height, 0)
      return ind.mount(chart, {
        scaleId: ind.panel.scaleId,
        scaleMargins: { top: topOffset / h, bottom: bottomOffset / h },
      })
    })

    const volSeries = chart.addSeries(VolSeries, {
      priceScaleId: 'volume',
      priceFormat: { type: 'volume' },
    })
    volSeries.priceScale().applyOptions({ scaleMargins: { top: (CANDLE_H + panelH) / h, bottom: 0 } })

    chartInstance = { chart, candleSeries }
    let lastCandles = params.candles
    let loadMoreTimer = null

    function requestMoreData(range) {
      if (!range || loadMoreTimer || loadedBars >= MAX_BARS) return
      const span = range.to - range.from
      const nearLeftEdge = range.from < -5
      const zoomedPastLoaded = span > lastCandles.length - 20
      if (!nearLeftEdge && !zoomedPastLoaded) return

      const target = Math.min(
        MAX_BARS,
        Math.max(loadedBars + Math.max(visible, 50), Math.ceil(span * 1.5))
      )
      if (target <= loadedBars) return

      loadMoreTimer = setTimeout(() => {
        loadedBars = target
        untrack(() => fetchData('load-more'))
        loadMoreTimer = null
      }, 120)
    }

    function handleVisibleLogicalRangeChange(range) {
      computeOverlay()
      requestMoreData(range)
    }

    chart.timeScale().subscribeVisibleLogicalRangeChange(handleVisibleLogicalRangeChange)

    function handleCrosshairMove(param) {
      hoveredTime = param?.time ?? null
    }

    chart.subscribeCrosshairMove(handleCrosshairMove)

    candleSeries.setData(params.candles)
    volSeries.setData(params.volume)
    mounted.forEach((m, i) => {
      m.setVisible(params.enabled[i])
      m.setAll(params.indicatorData[i] ?? [])
    })
    let pdLines = setPriceLines(candleSeries, params.pdHigh, params.pdLow)

    function scrollToLatest() {
      chart.timeScale().applyOptions({ barSpacing: CANDLE_PX, rightOffset: 0 })
      chart.timeScale().scrollToRealTime()
    }

    scrollToLatest()

    const ro = new ResizeObserver(() => {
      chart.resize(node.clientWidth, h)
    })
    ro.observe(node)

    return {
      update(p) {
        const dataChanged = p.candles !== lastCandles
        mounted.forEach((m, i) => m.setVisible(p.enabled[i]))

        if (!dataChanged) return
        const previousLength = lastCandles.length
        const previousRange = chart.timeScale().getVisibleLogicalRange?.()
        lastCandles = p.candles

        if (p.mode === 'incremental') {
          for (const c of p.candles.slice(-2)) candleSeries.update(c)
          for (const v of p.volume.slice(-2)) volSeries.update(v)
          mounted.forEach((m, i) => m.updateLast(p.indicatorData[i] ?? []))
        } else {
          candleSeries.setData(p.candles)
          volSeries.setData(p.volume)
          mounted.forEach((m, i) => m.setAll(p.indicatorData[i] ?? []))

          if (p.mode === 'load-more' && previousRange && p.candles.length > previousLength) {
            const added = p.candles.length - previousLength
            chart.timeScale().setVisibleLogicalRange({
              from: previousRange.from + added,
              to: previousRange.to + added,
            })
          } else {
            scrollToLatest()
          }
        }

        if (pdLines.high) candleSeries.removePriceLine(pdLines.high)
        if (pdLines.low)  candleSeries.removePriceLine(pdLines.low)
        pdLines = setPriceLines(candleSeries, p.pdHigh, p.pdLow)
        computeOverlay()
      },
      destroy() {
        if (loadMoreTimer) clearTimeout(loadMoreTimer)
        chart.timeScale().unsubscribeVisibleLogicalRangeChange(handleVisibleLogicalRangeChange)
        chart.unsubscribeCrosshairMove(handleCrosshairMove)
        hoveredTime = null
        mounted.forEach((m) => m.destroy())
        ro.disconnect()
        chart.remove()
        chartInstance = null
        overlay = null
      },
    }
  }
</script>

<div class="space-y-1" bind:clientWidth={containerWidth}>
  <div class="mb-3 space-y-2">
    <div class="flex items-center gap-1">
      <ToggleGroup.Root
        type="single"
        value={interval}
        onValueChange={changeInterval}
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

      <div class="flex items-center gap-1 ml-auto pl-2 border-l border-border">
        <button
          onclick={() => { measureMode = !measureMode }}
          class="flex items-center gap-1 px-2 py-0.5 text-xs rounded-md border transition-colors outline-none
            {measureMode
              ? 'border-primary text-primary bg-primary/10'
              : 'border-border text-muted-foreground hover:text-foreground hover:bg-secondary'}"
        >
          <Crosshair size={11} />
          R:R
        </button>
        {#each RR_OPTIONS as rr}
          <button
            onclick={() => setRR(rr)}
            class="px-1.5 py-0.5 text-xs rounded-sm border transition-colors outline-none
              {rrRatio === rr ? 'border-primary text-primary' : 'border-border text-muted-foreground hover:text-foreground'}"
          >
            {rr}R
          </button>
        {/each}
        {#if measurement}
          <button
            onclick={() => { measurement = null; overlay = null }}
            class="px-1 text-xs text-muted-foreground hover:text-foreground transition-colors leading-none"
            title="Clear measurement"
          >×</button>
        {/if}
      </div>
    </div>

    <div class="relative flex items-center gap-x-3 gap-y-1 border-t border-border pt-2">
      <div class="flex flex-wrap items-center gap-x-3 gap-y-1 min-w-0">
        {#each indicators as ind, i}
          {#if enabled[i] && ind.valueLabel && chartData?.indicatorData?.[i]?.length}
            <span class="text-xs" style={`color: ${ind.color}`}>
              {ind.valueLabel(chartData.indicatorData[i], hoveredTime)}
            </span>
          {/if}
        {/each}
      </div>

      <DropdownMenu.Root>
        <DropdownMenu.Trigger
          class="ml-auto shrink-0 p-1 rounded-md text-muted-foreground hover:text-foreground hover:bg-secondary transition-colors"
          title="Indicators"
        >
          <Settings2 size={13} />
        </DropdownMenu.Trigger>

        <DropdownMenu.Portal>
          <DropdownMenu.Content
            align="end"
            sideOffset={4}
            class="z-20 min-w-32 rounded-md border border-border bg-card shadow-lg overflow-hidden"
          >
            {#each menuIndicators as item}
              <DropdownMenu.Item
                onSelect={() => toggleMenuItem(item)}
                class="flex w-full items-center justify-between gap-3 px-3 py-1.5 text-left text-xs text-foreground hover:bg-secondary focus:bg-secondary outline-none transition-colors"
              >
                <span>{item.type === 'ema' ? item.name : item.ind.name}</span>
                <span class="text-muted-foreground">
                  {#if menuItemEnabled(item)}<Check size={12} />{/if}
                </span>
              </DropdownMenu.Item>
            {/each}
          </DropdownMenu.Content>
        </DropdownMenu.Portal>
      </DropdownMenu.Root>
    </div>
  </div>

  {#if loading}
    <Spinner />
  {:else if chartData?.error}
    <div class="text-destructive text-xs">{chartData.error}</div>
  {:else if chartData?.candles?.length}
    <div class="relative" style="height: {chartH}px">
      <div use:candleChart={{ candles: chartData.candles, volume: chartData.volume, indicatorData: chartData.indicatorData, enabled, pdHigh: chartData.pdHigh, pdLow: chartData.pdLow, mode: chartData.mode }}></div>

      {#if measureMode}
        <div
          class="absolute inset-0 z-10 cursor-crosshair"
          onmousedown={handleMeasureDown}
          onmousemove={handleMeasureMove}
          onmouseup={handleMeasureUp}
          onmouseleave={handleMeasureUp}
        ></div>
      {/if}

      {#if overlay && measurement}
        {@const { entryY, slY, tpY } = overlay}
        {@const isLong = slY > entryY}

        <!-- SL zone (red) — label at SL line (bottom for long, top for short) -->
        <div
          class="absolute inset-x-0 pointer-events-none bg-red-500/15 border-y border-red-500/30"
          style="top:{Math.min(entryY, slY)}px; height:{Math.max(Math.abs(slY - entryY), 1)}px"
        >
          <span class="absolute right-2 text-[10px] text-red-400 font-mono leading-none select-none {isLong ? 'bottom-0.5' : 'top-0.5'}">
            SL {measurement.slPrice.toFixed(2)}
          </span>
        </div>

        <!-- TP zone (green) — label at TP line (top for long, bottom for short) -->
        <div
          class="absolute inset-x-0 pointer-events-none bg-green-500/15 border-y border-green-500/30"
          style="top:{Math.min(entryY, tpY)}px; height:{Math.max(Math.abs(tpY - entryY), 1)}px"
        >
          <span class="absolute right-2 text-[10px] text-green-400 font-mono leading-none select-none {isLong ? 'top-0.5' : 'bottom-0.5'}">
            {rrRatio}R · {measurement.tpPrice.toFixed(2)}
          </span>
        </div>

        <!-- Entry line -->
        <div
          class="absolute inset-x-0 pointer-events-none border-t border-white/50 border-dashed"
          style="top:{entryY}px"
        >
          <span class="absolute right-2 top-0.5 text-[10px] text-blue-400 font-mono leading-none select-none">
            E {measurement.entryPrice.toFixed(2)}
          </span>
        </div>
      {/if}
    </div>

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
