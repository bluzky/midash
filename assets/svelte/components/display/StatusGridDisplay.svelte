<script>
  let { data, config = {} } = $props();
  let items = $derived(data?.items ?? []);
  let columns = $derived(config.columns ?? 3);
  let showMeta = $derived(config.showMeta ?? true);

  const STATUS = {
    ok: {
      dot: "bg-success",
      label: "text-success",
      border: "border-success/20",
    },
    warn: {
      dot: "bg-warning",
      label: "text-warning",
      border: "border-warning/20",
    },
    error: {
      dot: "bg-destructive",
      label: "text-destructive",
      border: "border-destructive/20",
    },
    unknown: {
      dot: "bg-muted-foreground",
      label: "text-muted-foreground",
      border: "border-border",
    },
  };

  const COLS = {
    1: "grid-cols-1",
    2: "grid-cols-2",
    3: "grid-cols-3",
    4: "grid-cols-4",
  };

  function statusOf(item) {
    return STATUS[item.status] ?? STATUS.unknown;
  }
</script>

{#if !items.length}
  <div class="text-muted-foreground text-sm">no items</div>
{:else}
  <div class="grid gap-2 {COLS[columns] ?? 'grid-cols-3'}">
    {#each items as item}
      {@const s = statusOf(item)}
      {#if item.href}
        <a
          href={item.href}
          target="_blank"
          class="rounded-lg border {s.border} p-2 hover:shadow-[0_4px_16px_rgba(28,25,23,0.06)] transition-all block"
        >
          <div class="flex items-center gap-1.5 min-w-0">
            <div class="w-2 h-2 rounded-full shrink-0 {s.dot}"></div>
            <span class="text-xs font-medium truncate text-foreground"
              >{item.name}</span
            >
          </div>
          {#if showMeta && item.meta}
            <div class="text-xs mt-1 truncate {s.label}">{item.meta}</div>
          {/if}
        </a>
      {:else}
        <div class="rounded-lg border {s.border} p-2">
          <div class="flex items-center gap-1.5 min-w-0">
            <div class="w-2 h-2 rounded-full shrink-0 {s.dot}"></div>
            <span class="text-xs font-medium truncate text-foreground"
              >{item.name}</span
            >
          </div>
          {#if showMeta && item.meta}
            <div class="text-xs mt-1 truncate {s.label}">{item.meta}</div>
          {/if}
        </div>
      {/if}
    {/each}
  </div>
{/if}
