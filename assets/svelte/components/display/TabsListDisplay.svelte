<script>
  import { Tabs } from 'bits-ui'
  import ListDisplay from './ListDisplay.svelte'

  let { data, config = {} } = $props()
  const { tabs = [] } = data ?? {}
  // svelte-ignore state_referenced_locally
  let active = $state(tabs[0]?.key ?? '')
</script>

{#if !tabs.length}
  <div class="text-muted-foreground text-sm">no data</div>
{:else}
  <Tabs.Root bind:value={active}>
    <Tabs.List class="flex gap-1 mb-3 border-b border-border">
      {#each tabs as tab}
        <Tabs.Trigger
          value={tab.key}
          class="flex items-center gap-1.5 px-3 py-1 text-sm font-mono transition-colors outline-none
            data-[state=active]:text-primary data-[state=active]:border-b-2 data-[state=active]:border-primary data-[state=active]:-mb-px
            data-[state=inactive]:text-muted-foreground hover:text-foreground hover:bg-secondary rounded-t-md"
        >
          {tab.label}
          {#if tab.count != null}
            <span class="text-xs tabular-nums px-1.5 py-0.5 rounded-full {tab.count > 0 ? 'bg-primary/15 text-primary' : 'bg-secondary text-muted-foreground'}">{tab.count}</span>
          {/if}
        </Tabs.Trigger>
      {/each}
    </Tabs.List>
    {#each tabs as tab}
      <Tabs.Content value={tab.key}>
        <ListDisplay data={{ items: tab.items ?? [] }} {config} />
      </Tabs.Content>
    {/each}
  </Tabs.Root>
{/if}
