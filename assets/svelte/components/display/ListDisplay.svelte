<script>
  let { data, config = {} } = $props()
  const { items = [] } = data ?? {}
  const { emptyMessage = 'no items', bordered = true } = config

  const BADGE = {
    default: 'bg-secondary text-foreground',
    success: 'bg-success/10 text-success',
    warning: 'bg-warning/10 text-warning',
    error: 'bg-destructive/10 text-destructive',
    info: 'bg-primary/10 text-primary',
  }

  const STATUS_DOT = {
    ok: 'bg-success',
    warn: 'bg-warning',
    error: 'bg-destructive',
    unknown: 'bg-muted-foreground',
  }
</script>

{#if !items.length}
  <div class="text-muted-foreground text-sm">{emptyMessage}</div>
{:else}
  <div class="space-y-3">
    {#each items as item}
      <div class={bordered ? 'border-l-2 border-border pl-3' : ''}>
        <div class="flex items-start justify-between gap-2">
          <div class="flex items-center gap-2 min-w-0">
            {#if item.status}
              <div class="w-2 h-2 rounded-full shrink-0 mt-0.5 {STATUS_DOT[item.status] ?? STATUS_DOT.unknown}"></div>
            {/if}
            {#if item.href}
              <a href={item.href} target="_blank" class="text-sm text-primary hover:underline truncate">{item.title}</a>
            {:else}
              <span class="text-sm text-foreground truncate">{item.title}</span>
            {/if}
          </div>
          {#if item.badge}
            <span class="text-xs px-1.5 py-0.5 rounded-sm shrink-0 {BADGE[item.badgeVariant ?? 'default']}">{item.badge}</span>
          {/if}
        </div>
        {#if item.subtitle || item.meta}
          <div class="flex items-center justify-between gap-2 mt-0.5">
            {#if item.subtitle}
              <span class="text-xs text-muted-foreground font-mono truncate">{item.subtitle}</span>
            {/if}
            {#if item.meta}
              <span class="text-xs text-muted-foreground shrink-0">{item.meta}</span>
            {/if}
          </div>
        {/if}
      </div>
    {/each}
  </div>
{/if}
