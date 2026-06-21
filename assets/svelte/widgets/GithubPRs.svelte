<script>
  import { get } from '../lib/api.js'
  import Spinner from '../components/Spinner.svelte'

  let { repos = [] } = $props()
  let reposData = $state({})
  let loading = $state(true)
  let error = $state(null)

  async function fetch() {
    loading = true
    error = null
    try {
      const qs = repos.map((r) => `repos[]=${encodeURIComponent(r)}`).join('&')
      const res = await get(`/api/github/prs?${qs}`)
      reposData = res.data
    } catch (e) {
      error = e.message
    } finally {
      loading = false
    }
  }

  export { fetch as refresh }
  fetch()

  function repoName(r) { return r.split('/').at(-1) }
  function prByAuthor(prs) {
    const map = {}
    for (const pr of prs) { map[pr.author] = (map[pr.author] ?? 0) + 1 }
    return Object.entries(map).sort((a, b) => b[1] - a[1])
  }
</script>

<div class="flex flex-col gap-3">
  {#if loading}
    <Spinner />
  {:else if error}
    <div class="text-destructive text-sm py-2">{error}</div>
  {:else}
    {#each repos as repo}
      {@const d = reposData[repo]}
      <div class="flex flex-col gap-1">
        <span class="text-sm text-muted-foreground">{repoName(repo)}</span>
        {#if !d}
          <div class="text-muted-foreground text-sm">—</div>
        {:else if d.error}
          <div class="text-destructive text-sm">{d.error}</div>
        {:else if d.prs.length === 0}
          <div class="text-muted-foreground text-sm">no open prs</div>
        {:else}
          <div class="flex flex-wrap gap-2">
            {#each prByAuthor(d.prs) as [author, count]}
              <a
                href="https://github.com/{repo}/pulls?q=is:pr+is:open+author:{author}"
                target="_blank"
                class="flex flex-col items-center rounded-md border border-border px-3 py-2 hover:bg-secondary transition-colors min-w-16"
              >
                <span class="text-sm text-muted-foreground">{author}</span>
                <span class="text-xl text-success tabular-nums">{count}</span>
              </a>
            {/each}
          </div>
        {/if}
      </div>
    {/each}
  {/if}
</div>
