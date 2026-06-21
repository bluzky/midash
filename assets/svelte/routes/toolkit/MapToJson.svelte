<script>
  import DashboardLayout from '../../components/DashboardLayout.svelte'
  import Col from '../../components/Col.svelte'
  import { navigate } from '../../lib/router.svelte.js'
  import { post } from '../../lib/api.js'

  const DEFAULT = '%{\n  name: "Alice",\n  age: 30,\n  tags: ["elixir", "phoenix"],\n  meta: %{active: true}\n}'

  let input = $state(DEFAULT)
  let output = $state(null)
  let error = $state(null)
  let loading = $state(false)
  let copied = $state(false)

  async function convert() {
    loading = true
    output = null
    error = null
    try {
      const res = await post('/api/toolkit/map-to-json', { input })
      if (res.error) error = res.error
      else output = res.output
    } catch (e) {
      error = e.message
    } finally {
      loading = false
    }
  }

  async function copy() {
    if (!output) return
    await navigator.clipboard.writeText(output)
    copied = true
    setTimeout(() => (copied = false), 1500)
  }
</script>

<DashboardLayout>
  <Col span={12}>
    <div class="mb-3 flex items-center gap-3">
      <button onclick={() => navigate('/toolkit')} class="text-xs text-muted-foreground hover:text-foreground transition-colors">← toolkit</button>
      <span class="text-xs text-muted-foreground">/</span>
      <span class="text-xs text-foreground">map → json</span>
    </div>

    <div class="flex flex-col gap-4">
      <div class="grid grid-cols-2 gap-4">
        <div class="flex flex-col gap-1">
          <label for="map-input" class="text-xs text-muted-foreground uppercase tracking-widest">Elixir Map</label>
          <textarea
            id="map-input"
            bind:value={input}
            class="h-96 w-full rounded-md border border-border bg-card p-3 font-mono text-sm text-foreground resize-none focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary/20"
            placeholder={'%{key: "value"}'}
            spellcheck="false"
          ></textarea>
        </div>
        <div class="flex flex-col gap-1">
          <span class="text-xs text-muted-foreground uppercase tracking-widest">JSON</span>
          <pre class="h-96 rounded-lg border border-border p-3 text-sm font-mono overflow-auto whitespace-pre-wrap {error ? 'bg-destructive/10 text-destructive' : 'bg-secondary text-foreground'}">{error ?? output ?? '// output appears here'}</pre>
        </div>
      </div>

      <div class="flex justify-between">
        <button
          onclick={convert}
          disabled={loading}
          class="btn-primary px-4 py-2 text-xs"
        >
          {loading ? 'converting...' : 'convert'}
        </button>
        {#if output}
          <button
            onclick={copy}
            class="px-4 py-2 rounded-md border border-border text-foreground text-xs font-medium hover:bg-secondary transition-colors"
          >
            {copied ? 'copied!' : 'copy'}
          </button>
        {/if}
      </div>
    </div>
  </Col>
</DashboardLayout>
