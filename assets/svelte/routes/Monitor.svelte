<script>
  import DashboardLayout from '../components/DashboardLayout.svelte'
  import Col from '../components/Col.svelte'
  import Widget from '../components/Widget.svelte'
  import DataWidget from '../components/DataWidget.svelte'
  import Spinner from '../components/Spinner.svelte'
  import { sentryIssues } from '../lib/sources/sentry.js'
  import { get } from '../lib/api.js'

  let entries = $state([])
  let loading = $state(true)

  async function loadConfig() {
    const res = await get('/api/config')
    entries = res.sentry_projects ?? []
    loading = false
  }

  loadConfig()

  function chunks(arr, size) {
    const result = []
    for (let i = 0; i < arr.length; i += size) result.push(arr.slice(i, i + size))
    return result
  }

  const columns = $derived(chunks(entries, Math.ceil(entries.length / 2) || 1))
</script>

<DashboardLayout>
  {#if loading}
    <Col span={12}>
      <Spinner />
    </Col>
  {:else if entries.length === 0}
    <Col span={12}>
      <Widget title="monitor">
        <p class="text-sm text-muted-foreground">
          Set <code class="bg-secondary px-1 rounded-lg">SENTRY_PROJECTS</code> env var to configure projects.
          <br />Format: <code class="bg-secondary px-1 rounded-lg">org/project:env1:env2</code>
        </p>
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
            config={{ sortable: true, defaultSort: 'count' }}
            poll={120}
          />
        {/each}
      </Col>
    {/each}
  {/if}
</DashboardLayout>
