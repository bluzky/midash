<script>
  import { get } from '../lib/api.js'
  import Spinner from '../components/Spinner.svelte'

  let { mode = 'count' } = $props()
  let tasks = $state([])
  let statuses = $state([])
  let teamId = $state('')
  let userId = $state('')
  let loading = $state(true)
  let error = $state(null)

  async function fetch() {
    loading = true
    error = null
    try {
      const res = await get('/api/clickup/tasks')
      tasks = res.data
      statuses = res.statuses
      teamId = res.team_id
      userId = res.user_id
    } catch (e) {
      error = e.message
    } finally {
      loading = false
    }
  }

  export { fetch as refresh }
  fetch()

  function countByStatus(key) {
    return tasks.filter((t) => (t.status?.status ?? '').toLowerCase() === key).length
  }

  function tasksByStatus(key) {
    return tasks.filter((t) => (t.status?.status ?? '').toLowerCase() === key)
  }

  function clickupUrl(statusKey) {
    const base = `https://app.clickup.com/${teamId}/home`
    const params = new URLSearchParams()
    params.set('assignees[]', userId)
    params.set('statuses[]', statusKey)
    return `${base}?${params.toString()}`
  }

  function formatDue(ms) {
    if (!ms) return ''
    const dt = new Date(parseInt(ms))
    const diff = Math.floor((dt - Date.now()) / 3600000)
    if (diff < 0) return 'overdue'
    if (diff < 24) return 'today'
    if (diff < 48) return 'tomorrow'
    return `${Math.floor(diff / 24)}d`
  }
</script>

{#if loading}
  <Spinner />
{:else if error}
  <div class="text-destructive text-sm py-2">{error}</div>
{:else if mode === 'count'}
  <div class="grid grid-cols-4 gap-2">
    {#each statuses as s}
      <a
        href={clickupUrl(s.key)}
        target="_blank"
        class="rounded-lg border border-border p-2 hover:shadow-[0_4px_16px_rgba(28,25,23,0.06)] transition-all block text-center"
      >
        <div class="text-sm leading-tight truncate uppercase font-medium" style="color: {s.color}">{s.label}</div>
        <div class="text-xl font-mono tabular-nums text-foreground mt-1">{countByStatus(s.key)}</div>
      </a>
    {/each}
  </div>
{:else}
  <div class="space-y-4">
    {#each statuses as s}
      {@const filtered = tasksByStatus(s.key)}
      {#if filtered.length > 0}
        <div>
          <div class="text-sm font-medium uppercase mb-2" style="color: {s.color}">{s.label} ({filtered.length})</div>
          <div class="space-y-2">
            {#each filtered as task}
              <div class="border-l-2 border-border pl-3">
                <a href={task.url} target="_blank" class="text-sm text-primary hover:underline block mb-1">
                  {task.name}
                </a>
                <div class="flex gap-3 text-xs text-muted-foreground">
                  {#if task.due_date}
                    <span class="{formatDue(task.due_date) === 'overdue' ? 'text-destructive' : ''}">{formatDue(task.due_date)}</span>
                  {/if}
                </div>
              </div>
            {/each}
          </div>
        </div>
      {/if}
    {/each}
  </div>
{/if}
