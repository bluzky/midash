<script>
  import { TrendingUp, TrendingDown, Minus } from '@lucide/svelte'

  let { data, config = {} } = $props()
  const { items = [] } = data ?? {}

  const TREND = {
    up: { icon: TrendingUp, class: 'text-success' },
    down: { icon: TrendingDown, class: 'text-destructive' },
    flat: { icon: Minus, class: 'text-muted-foreground' },
  }

  const COLS = { 2: 'grid-cols-2', 3: 'grid-cols-3', 4: 'grid-cols-4' }
  let cols = $derived(config.columns ?? Math.min(items.length, 4))
</script>

{#if !items.length}
  <div class="text-muted-foreground text-sm">no data</div>
{:else}
  <div class="grid gap-3 {COLS[cols] ?? 'grid-cols-2'}">
    {#each items as item}
      {@const trendInfo = item.trend ? TREND[item.trend] : null}
      <div class="rounded-lg border border-border p-3 flex flex-col items-center gap-1">
        <div class="flex items-end justify-center gap-1">
          <span
            class="text-2xl font-mono font-semibold tabular-nums leading-none"
            style={item.color ? `color: ${item.color}` : ''}
          >{item.value ?? '—'}</span>
          {#if trendInfo}
            <div class="flex items-center gap-0.5 mb-0.5 {trendInfo.class}">
              <svelte:component this={trendInfo.icon} class="w-3.5 h-3.5" />
              {#if item.delta}
                <span class="text-xs font-mono">{item.delta}</span>
              {/if}
            </div>
          {/if}
        </div>
        {#if item.label}
          <span class="text-xs text-muted-foreground uppercase tracking-wide truncate text-center">{item.label}</span>
        {/if}
      </div>
    {/each}
  </div>
{/if}
