<script>
  import DashboardLayout from '../components/DashboardLayout.svelte'
  import Col from '../components/Col.svelte'
  import Widget from '../components/Widget.svelte'
  import DataWidget from '../components/DataWidget.svelte'
  import { sentryIssues } from '../lib/sources/sentry.js'

  // Format: "org/project:env1:env2,..."
  const SENTRY_PROJECTS_ENV = import.meta.env.VITE_SENTRY_PROJECTS ?? ''

  function parseProjects(raw) {
    return raw
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean)
      .flatMap((entry) => {
        const parts = entry.split(':')
        if (parts.length < 2) return []
        const [projectSpec, ...envs] = parts
        const [org, project] = projectSpec.split('/')
        if (!org || !project) return []
        return envs.map((env) => ({ org, project, env }))
      })
  }

  const entries = parseProjects(SENTRY_PROJECTS_ENV)

  function chunks(arr, size) {
    const result = []
    for (let i = 0; i < arr.length; i += size) result.push(arr.slice(i, i + size))
    return result
  }

  const columns = chunks(entries, Math.ceil(entries.length / 2) || 1)
</script>

<DashboardLayout>
  {#if entries.length === 0}
    <Col span={12}>
      <Widget title="monitor">
        <p class="text-sm text-muted-foreground">
          Set <code class="bg-secondary px-1 rounded-lg">VITE_SENTRY_PROJECTS</code> env var to configure projects.
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
