<script>
  import DashboardLayout from '../components/DashboardLayout.svelte'
  import Col from '../components/Col.svelte'
  import Widget from '../components/Widget.svelte'
  import Spinner from '../components/Spinner.svelte'
  import { get } from '../lib/api.js'

  let apps = $state([])
  let loading = $state(true)
  let error = $state(null)

  async function fetchApps() {
    loading = true
    error = null
    try {
      const res = await get('/api/argocd/apps')
      apps = res.data
    } catch (e) {
      error = e.message
    } finally {
      loading = false
    }
  }

  fetchApps()
  const interval = setInterval(fetchApps, 60_000)
  $effect(() => () => clearInterval(interval))

  let grouped = $derived({
    prod: apps.filter((a) => a.name?.toLowerCase().includes('prod')),
    stg: apps.filter((a) => a.name?.toLowerCase().includes('stg')),
    other: apps.filter((a) => !a.name?.toLowerCase().includes('prod') && !a.name?.toLowerCase().includes('stg')),
  })

  function healthColor(s) {
    if (s === 'Healthy') return 'text-green-400'
    if (s === 'Degraded') return 'text-red-400'
    if (s === 'Progressing') return 'text-yellow-400'
    return 'text-muted-foreground'
  }

  function syncColor(s) {
    if (s === 'Synced') return 'text-green-400'
    if (s === 'OutOfSync') return 'text-yellow-400'
    return 'text-muted-foreground'
  }
</script>

{#snippet appList(list)}
  {#if loading}
    <Spinner />
  {:else if error}
    <div class="text-destructive text-sm px-1">{error}</div>
  {:else if list.length === 0}
    <div class="text-muted-foreground text-sm px-1">no apps</div>
  {:else}
    {#each list as app}
      <Widget title={app.name} collapsible>
        <div class="flex items-center gap-2 mb-2 text-xs text-muted-foreground">
          <span>app: <span class="{healthColor(app.health_status)}">{app.health_status}</span></span>
          <span>·</span>
          <span>sync: <span class="{syncColor(app.sync_status)}">{app.sync_status}</span></span>
        </div>
        {#each app.resources ?? [] as r}
          <div class="flex items-center justify-between py-1 text-sm font-mono border-t border-border">
            <span class="truncate text-foreground">{r.name}</span>
            <span class="{healthColor(r.health_status)} shrink-0 ml-2 text-xs">● {r.health_status}</span>
          </div>
        {/each}
      </Widget>
    {/each}
  {/if}
{/snippet}

<DashboardLayout>
  <Col span={4}>
    <div class="text-xs text-destructive uppercase tracking-widest mb-3 px-1">production</div>
    {@render appList(grouped.prod)}
  </Col>

  <Col span={4}>
    <div class="text-xs text-yellow-400 uppercase tracking-widest mb-3 px-1">staging</div>
    {@render appList(grouped.stg)}
  </Col>

  <Col span={4}>
    <div class="text-xs text-muted-foreground uppercase tracking-widest mb-3 px-1">dev / other</div>
    {@render appList(grouped.other)}
  </Col>
</DashboardLayout>
