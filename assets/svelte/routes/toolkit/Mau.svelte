<script>
  import DashboardLayout from '../../components/DashboardLayout.svelte'
  import Col from '../../components/Col.svelte'
  import { navigate } from '../../lib/router.svelte.js'
  import { post } from '../../lib/api.js'

  const DEFAULT_TPL = 'Hello, {{ name }}!\n\n{% if items %}\nItems:\n{% for item in items %}\n- {{ item | upper_case }}\n{% endfor %}\n{% endif %}'
  const DEFAULT_PARAMS = '{\n  "name": "World",\n  "items": ["apple", "banana", "cherry"]\n}'

  let template = $state(DEFAULT_TPL)
  let params = $state(DEFAULT_PARAMS)
  let output = $state(null)
  let error = $state(null)
  let loading = $state(false)

  async function render() {
    loading = true
    output = null
    error = null
    try {
      const res = await post('/api/toolkit/mau', { template, params })
      if (res.error) error = res.error
      else output = res.output
    } catch (e) {
      error = e.message
    } finally {
      loading = false
    }
  }
</script>

<DashboardLayout>
  <Col span={12}>
    <div class="mb-3 flex items-center gap-3">
      <button onclick={() => navigate('/toolkit')} class="text-xs text-muted-foreground hover:text-foreground transition-colors">← toolkit</button>
      <span class="text-xs text-muted-foreground">/</span>
      <span class="text-xs text-foreground">mau template</span>
    </div>

    <div class="flex flex-col gap-4">
      <div class="grid grid-cols-2 gap-4">
        <div class="flex flex-col gap-1">
          <label for="mau-template" class="text-xs text-muted-foreground uppercase tracking-widest">Template</label>
          <textarea
            id="mau-template"
            bind:value={template}
            class="h-72 w-full rounded-md border border-border bg-card p-3 font-mono text-sm text-foreground resize-none focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary/20"
            placeholder="Enter Mau template..."
            spellcheck="false"
          ></textarea>
        </div>
        <div class="flex flex-col gap-1">
          <label for="mau-params" class="text-xs text-muted-foreground uppercase tracking-widest">Params <span class="normal-case">(JSON)</span></label>
          <textarea
            id="mau-params"
            bind:value={params}
            class="h-72 w-full rounded-md border border-border bg-card p-3 font-mono text-sm text-foreground resize-none focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary/20"
            placeholder={'{"key": "value"}'}
            spellcheck="false"
          ></textarea>
        </div>
      </div>

      <button
        onclick={render}
        disabled={loading}
        class="btn-primary self-start px-4 py-2 text-xs"
      >
        {loading ? 'rendering...' : 'render'}
      </button>

      {#if output !== null || error !== null}
        <div class="flex flex-col gap-1">
          <span class="text-xs text-muted-foreground uppercase tracking-widest">Output</span>
          <pre class="rounded-md border border-border p-3 text-xs font-mono overflow-auto whitespace-pre-wrap {error ? 'bg-destructive/10 text-destructive' : 'bg-secondary text-success'}">{error ?? output}</pre>
        </div>
      {/if}
    </div>
  </Col>
</DashboardLayout>
