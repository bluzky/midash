<script>
  import { Collapsible } from 'bits-ui'
  import { RotateCw, ChevronDown } from '@lucide/svelte'

  let {
    title = null,
    collapsible = false,
    onRefresh = null,
    class: cls = '',
    headerClass = '',
    children,
  } = $props()

  let open = $state(true)
  let spinning = $state(false)

  async function handleRefresh() {
    if (!onRefresh) return
    spinning = true
    try { await onRefresh() } finally { spinning = false }
  }
</script>

<div class="mb-4 rounded-lg border border-border bg-card shadow-sm last:mb-0 {cls}">
  {#if title}
    <Collapsible.Root bind:open disabled={!collapsible}>
      <div class="px-4 py-2.5 border-b border-border text-xs uppercase tracking-widest flex items-center justify-between {headerClass || 'text-muted-foreground'}">
        <span>{title}</span>
        <span class="flex items-center gap-1">
          {#if onRefresh}
            <button
              onclick={handleRefresh}
              class="rounded-sm p-1 text-muted-foreground hover:text-foreground hover:bg-secondary transition-colors"
              title="refresh"
            >
              <RotateCw class="w-3.5 h-3.5 {spinning ? 'animate-spin' : ''}" />
            </button>
          {/if}
          {#if collapsible}
            <Collapsible.Trigger
              class="rounded-sm p-1 text-muted-foreground hover:text-foreground hover:bg-secondary transition-colors"
              title="collapse"
            >
              <ChevronDown class="w-3.5 h-3.5 transition-transform {open ? '' : '-rotate-90'}" />
            </Collapsible.Trigger>
          {/if}
        </span>
      </div>
      <Collapsible.Content>
        <div class="p-4">
          {@render children?.()}
        </div>
      </Collapsible.Content>
    </Collapsible.Root>
  {:else}
    <div class="p-4">
      {@render children?.()}
    </div>
  {/if}
</div>
