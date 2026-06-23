<script>
  let { data, config = {} } = $props();
  let items = $derived(data?.items ?? []);
  let emptyMessage = $derived(config.emptyMessage ?? "no items");
  let showAuthor = $derived(config.showAuthor ?? true);
</script>

{#if !items.length}
  <div class="text-muted-foreground text-sm">{emptyMessage}</div>
{:else}
  <div class="divide-y divide-border">
    {#each items as item}
      <div class="py-2.5 first:pt-0 last:pb-0">
        <div class="flex items-start justify-between gap-2 mb-0.5">
          {#if item.href}
            <a
              href={item.href}
              target="_blank"
              class="text-sm font-medium text-primary hover:underline leading-snug"
              >{item.title}</a
            >
          {:else}
            <span class="text-sm font-medium text-foreground leading-snug"
              >{item.title}</span
            >
          {/if}
          {#if item.time}
            <span class="text-xs text-muted-foreground shrink-0 tabular-nums"
              >{item.time}</span
            >
          {/if}
        </div>
        {#if showAuthor && item.author}
          <span class="text-xs text-muted-foreground">{item.author}</span>
          {#if item.body}<span class="text-xs text-muted-foreground">
              ·
            </span>{/if}
        {/if}
        {#if item.body}
          <span class="text-xs text-muted-foreground line-clamp-2"
            >{item.body}</span
          >
        {/if}
      </div>
    {/each}
  </div>
{/if}
