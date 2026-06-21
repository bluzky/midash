<script>
  import { get } from '../lib/api.js'
  import Spinner from '../components/Spinner.svelte'

  let { symbols = ['ETHUSDT', 'BTCUSDT'] } = $props()
  let data = $state([])
  let loading = $state(true)
  let error = $state(null)

  async function fetch() {
    try {
      loading = true
      error = null
      const qs = symbols.map((s) => `symbols[]=${s}`).join('&')
      const res = await get(`/api/crypto/funding?${qs}`)
      data = res.data
    } catch (e) {
      error = e.message
    } finally {
      loading = false
    }
  }

  fetch()
  const interval = setInterval(fetch, 5 * 60 * 1000)
  $effect(() => () => clearInterval(interval))

  export { fetch as refresh }

  function shortSym(s) {
    return s.replace('USDT', '').replace('USDC', '')
  }

  function fmtRate(r) {
    if (r == null) return '—'
    return (r >= 0 ? '+' : '') + (r * 100).toFixed(4) + '%'
  }

  function fmtAnnualized(r) {
    if (r == null) return '—'
    const d = r * 3 * 100
    return (d >= 0 ? '+' : '') + d.toFixed(4) + '% 24h'
  }

  function fmtOI(v) {
    if (v == null) return '—'
    if (v >= 1_000_000) return (v / 1_000_000).toFixed(2) + 'M'
    if (v >= 1_000) return (v / 1_000).toFixed(1) + 'K'
    return v.toFixed(0)
  }

  function fmtChange(v) {
    if (v == null) return '—'
    return (v >= 0 ? '+' : '') + v.toFixed(2) + '%'
  }

  function fmtPrice(p) {
    if (p == null) return '—'
    return p >= 1000
      ? '$' + Math.round(p).toLocaleString()
      : '$' + p.toFixed(2)
  }

  function fmtCountdown(ms) {
    if (!ms) return '—'
    const diff = Math.floor((ms - Date.now()) / 1000)
    if (diff <= 0) return 'now'
    if (diff < 3600) return `${Math.floor(diff / 60)}m ${diff % 60}s`
    return `${Math.floor(diff / 3600)}h ${Math.floor((diff % 3600) / 60)}m`
  }

  function rateColor(r) {
    if (r == null) return 'text-muted-foreground'
    if (r > 0.00004) return 'text-success'
    if (r < -0.00004) return 'text-destructive'
    return 'text-foreground'
  }

  function changeColor(v) {
    if (v == null) return 'text-muted-foreground'
    if (v > 0) return 'text-success'
    if (v < 0) return 'text-destructive'
    return 'text-muted-foreground'
  }
</script>

{#if loading}
  <Spinner />
{:else if error}
  <div class="text-destructive text-sm py-2">{error}</div>
{:else}
  <div class="space-y-4">
    {#each data as item}
      {#if !item.error}
        <div class="border border-border rounded-lg p-3 space-y-2">
          <div class="flex items-center justify-between">
            <span class="font-bold text-sm">{shortSym(item.symbol)}</span>
            <span class="text-muted-foreground text-xs">next funding {fmtCountdown(item.next_funding_time)}</span>
          </div>
          <div class="grid grid-cols-2 gap-2">
            <div class="space-y-0.5">
              <div class="text-muted-foreground text-xs uppercase tracking-wide">funding rate (8h)</div>
              <div class="text-base font-mono font-medium {rateColor(item.last_funding_rate)}">{fmtRate(item.last_funding_rate)}</div>
              <div class="text-muted-foreground text-xs">{fmtAnnualized(item.last_funding_rate)}</div>
            </div>
            <div class="space-y-0.5">
              <div class="text-muted-foreground text-xs uppercase tracking-wide">open interest</div>
              <div class="text-base font-mono font-medium text-foreground">{fmtOI(item.open_interest)}</div>
              <div class="text-muted-foreground text-xs">{shortSym(item.symbol)} tokens</div>
            </div>
          </div>
          <div class="grid grid-cols-3 gap-1 pt-1 border-t border-border">
            {#each [['OI 1h', item.oi_change_1h], ['OI 4h', item.oi_change_4h], ['OI 24h', item.oi_change_24h]] as [label, val]}
              <div class="space-y-0.5">
                <div class="text-muted-foreground text-xs">{label}</div>
                <div class="font-mono text-xs font-medium {changeColor(val)}">{fmtChange(val)}</div>
              </div>
            {/each}
          </div>
          <div class="grid grid-cols-2 gap-2 pt-1 border-t border-border">
            <div class="space-y-0.5">
              <div class="text-muted-foreground text-xs">mark price</div>
              <div class="font-mono text-xs text-foreground">{fmtPrice(item.mark_price)}</div>
            </div>
            <div class="space-y-0.5">
              <div class="text-muted-foreground text-xs">index price</div>
              <div class="font-mono text-xs text-foreground">{fmtPrice(item.index_price)}</div>
            </div>
          </div>
        </div>
      {/if}
    {/each}
  </div>
{/if}
