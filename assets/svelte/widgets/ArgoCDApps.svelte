<script>
  import { get } from '../lib/api.js'
  import Spinner from '../components/Spinner.svelte'

  let apps = $state([])
  let loading = $state(true)
  let error = $state(null)

  async function fetch() {
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

  export { fetch as refresh }
  fetch()
  const interval = setInterval(fetch, 60_000)
  $effect(() => () => clearInterval(interval))

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

{#if loading}
  <Spinner />
{:else if error}
  <div class="text-destructive text-sm py-2">{error}</div>
{:else if apps.length === 0}
  <div class="text-muted-foreground text-sm">no apps</div>
{:else}
  <div class="space-y-4">
    {#each apps as app}
      <div class="border border-border rounded-lg p-3">
        <div class="flex items-center gap-2 mb-2">
          <span class="font-mono text-sm text-foreground">{app.name}</span>
          <span class="text-xs {healthColor(app.health_status)}">{app.health_status}</span>
          <span class="text-xs text-muted-foreground">·</span>
          <span class="text-xs {syncColor(app.sync_status)}">{app.sync_status}</span>
        </div>
        {#if app.resources?.length}
          <div class="divide-y divide-border">
            {#each app.resources as r}
              <div class="flex items-center justify-between py-1 text-xs font-mono">
                <span class="text-foreground truncate">{r.name}</span>
                <span class="{healthColor(r.health_status)} shrink-0 ml-2">● {r.health_status}</span>
              </div>
            {/each}
          </div>
        {/if}
      </div>
    {/each}
  </div>
{/if}
