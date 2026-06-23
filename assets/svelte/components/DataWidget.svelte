<script>
  import Widget from "./Widget.svelte";
  import Spinner from "./Spinner.svelte";
  import ConfigDialog from "./ConfigDialog.svelte";
  import { Settings2 } from "@lucide/svelte";
  import { configFieldsFor, configTitleFor } from "../lib/config-schema.js";
  import ListDisplay from "./display/ListDisplay.svelte";
  import TableDisplay from "./display/TableDisplay.svelte";
  import KeyValueDisplay from "./display/KeyValueDisplay.svelte";
  import StatDisplay from "./display/StatDisplay.svelte";
  import StatGroupDisplay from "./display/StatGroupDisplay.svelte";
  import StatusGridDisplay from "./display/StatusGridDisplay.svelte";
  import ProgressDisplay from "./display/ProgressDisplay.svelte";
  import MarkdownDisplay from "./display/MarkdownDisplay.svelte";
  import LineChartDisplay from "./display/LineChartDisplay.svelte";
  import AreaChartDisplay from "./display/AreaChartDisplay.svelte";
  import TimelineDisplay from "./display/TimelineDisplay.svelte";
  import FeedDisplay from "./display/FeedDisplay.svelte";
  import TabsListDisplay from "./display/TabsListDisplay.svelte";

  const DISPLAYS = {
    list: ListDisplay,
    table: TableDisplay,
    "key-value": KeyValueDisplay,
    stat: StatDisplay,
    "stat-group": StatGroupDisplay,
    "status-grid": StatusGridDisplay,
    progress: ProgressDisplay,
    markdown: MarkdownDisplay,
    "line-chart": LineChartDisplay,
    "area-chart": AreaChartDisplay,
    timeline: TimelineDisplay,
    feed: FeedDisplay,
    "tabs-list": TabsListDisplay,
  };

  let {
    source,
    display,
    config = {},
    poll = null,
    title = null,
    collapsible = false,
    class: cls = "",
    headerClass = "",
    configGroup = null,
  } = $props();

  let data = $state(null);
  let loading = $state(true);
  let error = $state(null);
  let configOpen = $state(false);

  let missingKey = $derived(
    error?.match(/([A-Z0-9_]+) not configured/)?.[1] ?? null,
  );
  let configKey = $derived(missingKey ?? configGroup);
  let configFields = $derived(configFieldsFor(configKey));
  let configTitle = $derived(configTitleFor(configKey));

  async function load() {
    if (data === null) loading = true;
    error = null;
    try {
      data = await source();
    } catch (e) {
      error = e.message;
    } finally {
      loading = false;
    }
  }

  load();

  $effect(() => {
    if (!poll) return;
    const id = setInterval(load, poll * 1000);
    return () => clearInterval(id);
  });

  let DisplayComponent = $derived(DISPLAYS[display]);
</script>

<Widget {title} {collapsible} class={cls} {headerClass} onRefresh={load}>
  {#if loading}
    <Spinner />
  {:else if error}
    <div
      class="flex flex-col items-center justify-center gap-3 py-4 text-center"
    >
      <div class="text-destructive text-sm">{error}</div>
      {#if configFields.length}
        <button
          onclick={() => (configOpen = true)}
          class="inline-flex items-center gap-1.5 rounded-md border border-border px-3 py-1.5 text-sm text-foreground hover:bg-secondary transition-colors"
        >
          <Settings2 class="h-3.5 w-3.5" />
          <span>configure</span>
        </button>
      {/if}
    </div>
  {:else if DisplayComponent}
    <DisplayComponent {data} {config} />
  {:else}
    <div class="text-muted-foreground text-sm">unknown display: {display}</div>
  {/if}
</Widget>

<ConfigDialog
  bind:open={configOpen}
  title={configTitle}
  fields={configFields}
  onSaved={load}
/>
