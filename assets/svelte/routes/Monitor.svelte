<script>
  import DashboardLayout from "../components/DashboardLayout.svelte";
  import Col from "../components/Col.svelte";
  import Widget from "../components/Widget.svelte";
  import DataWidget from "../components/DataWidget.svelte";
  import Spinner from "../components/Spinner.svelte";
  import ConfigDialog from "../components/ConfigDialog.svelte";
  import { Settings2 } from "@lucide/svelte";
  import { sentryIssues } from "../lib/sources/sentry.js";
  import { get } from "../lib/api.js";
  import { configFieldsFor, configTitleFor } from "../lib/config-schema.js";

  const CONFIG_KEY = "SENTRY_TOKEN";

  let entries = $state([]);
  let loading = $state(true);
  let configOpen = $state(false);

  async function loadConfig() {
    const res = await get("/api/config");
    entries = res.sentry_projects ?? [];
    loading = false;
  }

  loadConfig();

  function chunks(arr, size) {
    const result = [];
    for (let i = 0; i < arr.length; i += size)
      result.push(arr.slice(i, i + size));
    return result;
  }

  const columns = $derived(chunks(entries, Math.ceil(entries.length / 2) || 1));
</script>

<DashboardLayout>
  {#if loading}
    <Col span={12}>
      <Spinner />
    </Col>
  {:else if entries.length === 0}
    <Col span={12}>
      <Widget title="monitor">
        <div
          class="flex flex-col items-center justify-center gap-3 py-4 text-center"
        >
          <p class="text-sm text-muted-foreground">
            Configure <code class="bg-secondary px-1 rounded-lg"
              >SENTRY_TOKEN</code
            >
            and
            <code class="bg-secondary px-1 rounded-lg">SENTRY_PROJECTS</code>.
            <br />Format:
            <code class="bg-secondary px-1 rounded-lg"
              >org/project:env1:env2</code
            >
          </p>
          <button
            onclick={() => (configOpen = true)}
            class="inline-flex items-center gap-1.5 rounded-md border border-border px-3 py-1.5 text-sm text-foreground hover:bg-secondary transition-colors"
          >
            <Settings2 class="h-3.5 w-3.5" />
            <span>configure</span>
          </button>
        </div>
      </Widget>
    </Col>
  {:else}
    {#each columns as col}
      <Col span={6}>
        {#each col as { org, project, env }}
          <DataWidget
            title="{org}/{project} · {env}"
            collapsible
            display="table"
            source={sentryIssues({ org, project, environment: env })}
            config={{ sortable: true, defaultSort: "count" }}
            configGroup="SENTRY_TOKEN"
            poll={120}
          />
        {/each}
      </Col>
    {/each}
  {/if}
</DashboardLayout>

<ConfigDialog
  bind:open={configOpen}
  title={configTitleFor(CONFIG_KEY)}
  fields={configFieldsFor(CONFIG_KEY)}
  onSaved={loadConfig}
/>
