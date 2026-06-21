<script>
  import Widget from './Widget.svelte'
  import Spinner from './Spinner.svelte'
  import ListDisplay from './display/ListDisplay.svelte'
  import TableDisplay from './display/TableDisplay.svelte'
  import KeyValueDisplay from './display/KeyValueDisplay.svelte'
  import StatDisplay from './display/StatDisplay.svelte'
  import StatGroupDisplay from './display/StatGroupDisplay.svelte'
  import StatusGridDisplay from './display/StatusGridDisplay.svelte'
  import ProgressDisplay from './display/ProgressDisplay.svelte'
  import MarkdownDisplay from './display/MarkdownDisplay.svelte'
  import LineChartDisplay from './display/LineChartDisplay.svelte'
  import AreaChartDisplay from './display/AreaChartDisplay.svelte'
  import TimelineDisplay from './display/TimelineDisplay.svelte'
  import FeedDisplay from './display/FeedDisplay.svelte'

  const DISPLAYS = {
    list: ListDisplay,
    table: TableDisplay,
    'key-value': KeyValueDisplay,
    stat: StatDisplay,
    'stat-group': StatGroupDisplay,
    'status-grid': StatusGridDisplay,
    progress: ProgressDisplay,
    markdown: MarkdownDisplay,
    'line-chart': LineChartDisplay,
    'area-chart': AreaChartDisplay,
    timeline: TimelineDisplay,
    feed: FeedDisplay,
  }

  let {
    source,
    display,
    config = {},
    poll = null,
    title = null,
    collapsible = false,
    class: cls = '',
    headerClass = '',
  } = $props()

  let data = $state(null)
  let loading = $state(true)
  let error = $state(null)

  async function load() {
    if (data === null) loading = true
    error = null
    try {
      data = await source()
    } catch (e) {
      error = e.message
    } finally {
      loading = false
    }
  }

  load()

  $effect(() => {
    if (!poll) return
    const id = setInterval(load, poll * 1000)
    return () => clearInterval(id)
  })

  let DisplayComponent = $derived(DISPLAYS[display])
</script>

<Widget {title} {collapsible} class={cls} {headerClass} onRefresh={load}>
  {#if loading}
    <Spinner />
  {:else if error}
    <div class="text-destructive text-sm py-2">{error}</div>
  {:else if DisplayComponent}
    <svelte:component this={DisplayComponent} {data} {config} />
  {:else}
    <div class="text-muted-foreground text-sm">unknown display: {display}</div>
  {/if}
</Widget>
