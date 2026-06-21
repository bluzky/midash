<script>
  import { Tabs } from 'bits-ui'
  import { get } from '../lib/api.js'
  import { Clipboard } from '@lucide/svelte'
  import Spinner from '../components/Spinner.svelte'

  let { repos = [] } = $props()
  let reposData = $state({})
  let loading = $state(true)
  let error = $state(null)
  // svelte-ignore state_referenced_locally
  let activeTab = $state(repos[0] ?? '')

  async function fetch() {
    loading = true
    error = null
    try {
      const qs = repos.map((r) => `repos[]=${encodeURIComponent(r)}`).join('&')
      const res = await get(`/api/github/my-prs?${qs}`)
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

  function relTime(iso) {
    const diff = Math.floor((Date.now() - new Date(iso)) / 3600000)
    if (diff < 1) return 'just now'
    if (diff < 24) return `${diff}h ago`
    return `${Math.floor(diff / 24)}d ago`
  }

  function copyBranch(branch) {
    navigator.clipboard.writeText(branch)
  }
</script>

<Tabs.Root bind:value={activeTab}>
  <Tabs.List class="flex gap-1 mb-3 border-b border-border">
    {#each repos as repo}
      <Tabs.Trigger
        value={repo}
        class="px-3 py-1 text-sm font-mono transition-colors outline-none
          data-[state=active]:text-foreground data-[state=active]:border-b-2 data-[state=active]:border-foreground data-[state=active]:-mb-px
          data-[state=inactive]:text-muted-foreground hover:text-foreground"
      >
        {repoName(repo)}
      </Tabs.Trigger>
    {/each}
  </Tabs.List>

  {#if loading}
    <Spinner />
  {:else if error}
    <div class="text-destructive text-sm py-2">{error}</div>
  {:else}
    {#each repos as repo}
      <Tabs.Content value={repo}>
        {@const d = reposData[repo]}
        {#if d?.error}
          <div class="text-destructive text-sm">{d.error}</div>
        {:else if !d?.prs?.length}
          <div class="text-muted-foreground text-sm">no open prs</div>
        {:else}
          <div class="space-y-3">
            {#each d.prs as pr}
              <div class="border-l-2 border-border pl-3">
                <a href={pr.html_url} target="_blank" class="text-sm text-info hover:underline block mb-1">
                  <span class="text-muted-foreground">#{pr.number}</span> {pr.title}
                </a>
                <div class="flex gap-3 text-xs text-muted-foreground">
                  <span class="text-warning">{pr.approvals} approvals</span>
                  <span>{relTime(pr.created_at)}</span>
                </div>
                {#if pr.head_ref}
                  <div class="flex items-center gap-1 mt-1">
                    <span class="text-xs text-muted-foreground font-mono truncate">{pr.head_ref}</span>
                    <button
                      onclick={() => copyBranch(pr.head_ref)}
                      class="text-muted-foreground hover:text-foreground transition-colors shrink-0"
                      title="Copy branch"
                    >
                      <Clipboard class="w-3 h-3" />
                    </button>
                  </div>
                {/if}
              </div>
            {/each}
          </div>
        {/if}
      </Tabs.Content>
    {/each}
  {/if}
</Tabs.Root>
