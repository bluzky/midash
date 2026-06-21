<script>
  import { get } from '../lib/api.js'
  import Spinner from '../components/Spinner.svelte'

  let { org, project, environment } = $props()
  let issues = $state([])
  let initialLoading = $state(true)
  let error = $state(null)
  let sort = $state('freq')

  const SORT_OPTIONS = [
    { value: 'freq', label: 'highest events' },
    { value: 'date', label: 'last seen' },
    { value: 'user', label: 'affected users' },
    { value: 'new', label: 'first seen' },
    { value: 'trends', label: 'rising issues' },
  ]

  async function fetch() {
    error = null
    try {
      const res = await get(`/api/sentry/issues?org=${org}&project=${project}&environment=${environment}&sort=${sort}`)
      issues = res.data
    } catch (e) {
      error = e.message
    } finally {
      initialLoading = false
    }
  }

  export { fetch as refresh }
  fetch()

  function fmtCount(n) {
    const c = parseInt(n)
    if (c >= 1_000_000) return (c / 1_000_000).toFixed(1) + 'M'
    if (c >= 1000) return (c / 1000).toFixed(1) + 'K'
    return String(c)
  }

  function fmtLastSeen(iso) {
    if (!iso) return '—'
    const diff = Math.floor((Date.now() - new Date(iso)) / 1000)
    if (diff < 60) return 'now'
    if (diff < 3600) return `${Math.floor(diff / 60)}m ago`
    if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`
    if (diff < 604800) return `${Math.floor(diff / 86400)}d ago`
    return `${Math.floor(diff / 604800)}w ago`
  }
</script>

{#if initialLoading}
  <Spinner />
{:else if error}
  <div class="text-destructive text-sm py-2">{error}</div>
{:else}
  <div class="mb-2 flex items-center justify-end gap-2">
    <label for="sentry-sort-{org}-{project}" class="text-muted-foreground text-sm">sort:</label>
    <select
      id="sentry-sort-{org}-{project}"
      bind:value={sort}
      onchange={fetch}
      class="bg-card border border-border rounded-md text-sm px-2 py-1 text-foreground cursor-pointer focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary/20"
    >
      {#each SORT_OPTIONS as opt}
        <option value={opt.value}>{opt.label}</option>
      {/each}
    </select>
  </div>

  {#if issues.length === 0}
    <div class="text-muted-foreground text-sm">no issues in 24h</div>
  {:else}
    <table class="w-full table-fixed text-sm">
      <thead>
        <tr class="border-b border-border text-muted-foreground text-xs uppercase">
          <th class="text-left py-1 px-0 font-normal">title</th>
          <th class="text-right py-1 px-0 font-normal w-16">last seen</th>
          <th class="text-right py-1 px-0 font-normal w-20">events</th>
        </tr>
      </thead>
      <tbody class="divide-y divide-border">
        {#each issues as issue (issue.id)}
          {@const count = parseInt(issue.count)}
          {@const hot = count > 1000}
          <tr class="hover:bg-secondary transition-colors">
            <td class="py-1 px-0 min-w-0">
              <a
                href={issue.url}
                target="_blank"
                title={issue.title}
                class="block truncate underline {hot ? 'text-destructive font-semibold' : 'text-foreground'}"
              >
                {issue.title}
              </a>
            </td>
            <td class="py-1 px-0 text-right text-muted-foreground text-xs w-16 shrink-0">
              {fmtLastSeen(issue.lastSeen)}
            </td>
            <td class="py-1 px-0 text-right w-20 shrink-0">
              <span class="bg-secondary/50 px-2 py-0.5 rounded-full text-sm font-mono font-medium tabular-nums inline-block {hot ? 'text-destructive' : 'text-foreground'}">
                {fmtCount(issue.count)}
              </span>
            </td>
          </tr>
        {/each}
      </tbody>
    </table>
  {/if}
{/if}
