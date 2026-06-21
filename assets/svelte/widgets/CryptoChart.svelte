<script>
  import { ToggleGroup } from 'bits-ui'
  import { get } from '../lib/api.js'
  import Spinner from '../components/Spinner.svelte'

  let { symbols = ['ETHUSDT', 'BTCUSDT'] } = $props()

  const INTERVALS = [
    { key: '15m', label: '15m' },
    { key: '1h', label: '1h' },
    { key: '4h', label: '4h' },
    { key: '1d', label: '1d' },
  ]
  const CHART_H = 150
  const VISIBLE = 72

  let interval = $state('1h')
  let charts = $state({})
  let loading = $state(true)
  let countdown = $state(60)

  async function fetchAll() {
    loading = true
    const results = {}
    for (const sym of symbols) {
      try {
        const res = await get(`/api/crypto/klines?symbol=${sym}&interval=${interval}&limit=${VISIBLE + 20}`)
        results[sym] = { candles: res.data.slice(-VISIBLE), error: null }
      } catch (e) {
        results[sym] = { candles: [], error: e.message }
      }
    }
    charts = results
    loading = false
    countdown = 60
  }

  export async function refresh() { await fetchAll() }

  fetchAll()

  const refreshInterval = setInterval(fetchAll, 60_000)
  const countdownInterval = setInterval(() => { if (countdown > 0) countdown-- }, 1000)
  $effect(() => () => { clearInterval(refreshInterval); clearInterval(countdownInterval) })

  function renderSVG(candles) {
    if (!candles?.length) return ''
    const prices = candles.flatMap((c) => [c.high, c.low])
    const minP = Math.min(...prices)
    const maxP = Math.max(...prices)
    const range = maxP - minP || 1
    const W = 600
    const cw = Math.floor(W / candles.length)
    const gap = Math.max(1, Math.floor(cw * 0.15))
    const bw = Math.max(1, cw - gap * 2)

    function py(price) {
      return CHART_H - ((price - minP) / range) * CHART_H
    }

    const rects = candles.map((c, i) => {
      const x = i * cw + gap
      const isGreen = c.close >= c.open
      const color = isGreen ? '#16a34a' : '#dc2626'
      const bodyTop = py(Math.max(c.open, c.close))
      const bodyBot = py(Math.min(c.open, c.close))
      const bodyH = Math.max(1, bodyBot - bodyTop)
      const wickX = x + bw / 2
      return `
        <line x1="${wickX}" y1="${py(c.high)}" x2="${wickX}" y2="${py(c.low)}" stroke="${color}" stroke-width="1" opacity="0.6"/>
        <rect x="${x}" y="${bodyTop}" width="${bw}" height="${bodyH}" fill="${color}"/>
      `
    }).join('')

    return `<svg viewBox="0 0 ${W} ${CHART_H}" class="w-full" style="height:${CHART_H}px">${rects}</svg>`
  }
</script>

<div class="space-y-1">
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
    <span class="ml-auto text-xs text-muted-foreground self-center">refresh in {countdown}s</span>
  </div>

  {#if loading}
    <Spinner />
  {:else}
    {#each symbols as sym}
      {@const chart = charts[sym]}
      <div class="mb-4">
        <div class="text-xs text-muted-foreground font-mono mb-1">{sym}</div>
        {#if chart?.error}
          <div class="text-destructive text-xs">{chart.error}</div>
        {:else if chart?.candles?.length}
          {@html renderSVG(chart.candles)}
          {@const last = chart.candles.at(-1)}
          <div class="flex gap-4 text-xs text-muted-foreground font-mono mt-1">
            <span>O {last.open.toFixed(2)}</span>
            <span>H {last.high.toFixed(2)}</span>
            <span>L {last.low.toFixed(2)}</span>
            <span class="{last.close >= last.open ? 'text-success' : 'text-destructive'}">C {last.close.toFixed(2)}</span>
          </div>
        {/if}
      </div>
    {/each}
  {/if}
</div>
