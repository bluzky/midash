<script>
  import { TrendingUp, TrendingDown, Minus } from '@lucide/svelte'

  let { data, config = {} } = $props()
  const { value = '—', label, trend, delta, color } = data ?? {}
  const { centered = true } = config

  const TREND = {
    up: { icon: TrendingUp, class: 'text-success' },
    down: { icon: TrendingDown, class: 'text-destructive' },
    flat: { icon: Minus, class: 'text-muted-foreground' },
  }

  let trendInfo = $derived(trend ? TREND[trend] : null)
</script>

<div class={centered ? 'flex flex-col items-center justify-center py-2 gap-1' : 'flex flex-col gap-1'}>
  <div class="flex items-end gap-2">
    <span
      class="text-3xl font-mono font-semibold tabular-nums leading-none"
      style={color ? `color: ${color}` : ''}
    >{value}</span>
    {#if trendInfo}
      <div class="flex items-center gap-1 mb-0.5 {trendInfo.class}">
        <svelte:component this={trendInfo.icon} class="w-4 h-4" />
        {#if delta}
          <span class="text-xs font-mono">{delta}</span>
        {/if}
      </div>
    {/if}
  </div>
  {#if label}
    <span class="text-xs text-muted-foreground uppercase tracking-wide">{label}</span>
  {/if}
</div>
