<script>
  let { data, config = {} } = $props();
  let events = $derived(data?.events ?? []);
  let emptyMessage = $derived(config.emptyMessage ?? "no events");

  const STATUS_DOT = {
    ok: "bg-success",
    warn: "bg-warning",
    error: "bg-destructive",
    unknown: "bg-muted-foreground",
  };
</script>

{#if !events.length}
  <div class="text-muted-foreground text-sm">{emptyMessage}</div>
{:else}
  <div class="relative">
    <!-- vertical line -->
    <div class="absolute left-[7px] top-2 bottom-2 w-px bg-border"></div>

    <div class="space-y-4">
      {#each events as event}
        {@const dot = STATUS_DOT[event.status ?? "unknown"]}
        <div class="flex gap-3 relative">
          <div class="w-4 flex flex-col items-center shrink-0 pt-0.5">
            <div
              class="w-3.5 h-3.5 rounded-full border-2 border-background {dot} shrink-0 z-10"
            ></div>
          </div>
          <div class="flex-1 min-w-0 pb-1">
            <div class="flex items-start justify-between gap-2">
              {#if event.href}
                <a
                  href={event.href}
                  target="_blank"
                  class="text-sm text-primary hover:underline leading-snug"
                  >{event.title}</a
                >
              {:else}
                <span class="text-sm text-foreground leading-snug"
                  >{event.title}</span
                >
              {/if}
              {#if event.time}
                <span
                  class="text-xs text-muted-foreground shrink-0 tabular-nums"
                  >{event.time}</span
                >
              {/if}
            </div>
            {#if event.body}
              <p class="text-xs text-muted-foreground mt-0.5 leading-relaxed">
                {event.body}
              </p>
            {/if}
          </div>
        </div>
      {/each}
    </div>
  </div>
{/if}
