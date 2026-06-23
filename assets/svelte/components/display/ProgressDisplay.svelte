<script>
  let { data, config = {} } = $props();
  let items = $derived(data?.items ?? []);
  let showPercent = $derived(config.showPercent ?? true);
  let showValues = $derived(config.showValues ?? false);

  function pct(value, max) {
    if (!max) return 0;
    return Math.min(100, Math.round((value / max) * 100));
  }
</script>

{#if !items.length}
  <div class="text-muted-foreground text-sm">no data</div>
{:else}
  <div class="space-y-3">
    {#each items as item}
      {@const p = pct(item.value, item.max)}
      <div>
        <div class="flex items-center justify-between mb-1">
          <span class="text-sm text-foreground">{item.label}</span>
          <span class="text-xs text-muted-foreground tabular-nums">
            {#if showValues}{item.value}/{item.max}{/if}
            {#if showPercent}{p}%{/if}
          </span>
        </div>
        <div class="h-1.5 rounded-full bg-secondary overflow-hidden">
          <div
            class="h-full rounded-full transition-all duration-300"
            style="width: {p}%; background-color: {item.color ??
              'var(--primary)'}"
          ></div>
        </div>
      </div>
    {/each}
  </div>
{/if}
