<script>
  let { data, config = {} } = $props();
  let pairs = $derived(data?.pairs ?? []);
  let emptyMessage = $derived(config.emptyMessage ?? "no data");

  const STATUS_DOT = {
    ok: "bg-success",
    warn: "bg-warning",
    error: "bg-destructive",
    unknown: "bg-muted-foreground",
  };
</script>

{#if !pairs.length}
  <div class="text-muted-foreground text-sm">{emptyMessage}</div>
{:else}
  <div class="space-y-3">
    {#each pairs as pair}
      <div class="flex items-baseline justify-between gap-2">
        <div class="flex items-center gap-1.5 min-w-0">
          {#if pair.status}
            <div
              class="w-2 h-2 rounded-full shrink-0 {STATUS_DOT[pair.status] ??
                STATUS_DOT.unknown}"
            ></div>
          {/if}
          <span class="text-xs text-muted-foreground truncate">{pair.key}</span>
        </div>
        <div class="flex items-center gap-1.5 shrink-0">
          <span
            class="text-sm tabular-nums text-foreground font-mono tracking-tight"
            >{pair.value}</span
          >
          {#if pair.meta}
            <span class="text-xs text-muted-foreground">{pair.meta}</span>
          {/if}
        </div>
      </div>
    {/each}
  </div>
{/if}
