<script>
  import DashboardLayout from '../../components/DashboardLayout.svelte'
  import Col from '../../components/Col.svelte'
  import { navigate } from '../../lib/router.svelte.js'
  import { post } from '../../lib/api.js'
  import { onMount } from 'svelte'

  const STARTER = '# `input` is available as a variable\n# Example: String.upcase(input)\ninput\n'

  let input = $state('')
  let output = $state(null)
  let error = $state(null)
  let loading = $state(false)
  let editorEl

  onMount(async () => {
    const { CodeJar } = await import('codejar')
    const Prism = (await import('prismjs')).default
    await import('prismjs/components/prism-elixir.js')

    const highlight = (el) => {
      el.innerHTML = Prism.highlight(el.textContent, Prism.languages.elixir, 'elixir')
    }

    const jar = CodeJar(editorEl, highlight, { tab: '  ', addClosing: false })
    jar.updateCode(STARTER)
    editorEl._jar = jar
  })

  async function run() {
    const code = editorEl?._jar?.toString() ?? ''
    loading = true
    output = null
    error = null
    try {
      const res = await post('/api/toolkit/execute', { code, input })
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
      <button
        onclick={() => navigate('/toolkit')}
        class="text-xs text-muted-foreground hover:text-foreground transition-colors font-mono"
      >
        ← toolkit
      </button>
      <span class="text-xs text-muted-foreground">/</span>
      <span class="text-xs text-foreground font-mono">elixir execute</span>
    </div>

    <div class="flex flex-col gap-4">
      <div class="grid grid-cols-2 gap-4">
        <div class="flex flex-col gap-1">
          <label for="elixir-input" class="text-xs text-muted-foreground uppercase tracking-widest">Input</label>
          <textarea
            id="elixir-input"
            bind:value={input}
            rows="16"
            placeholder="Enter input string..."
            class="h-64 w-full rounded-lg border border-border bg-background p-3 font-mono text-sm text-foreground resize-none focus:outline-none focus:ring-1 focus:ring-ring"
          ></textarea>
        </div>
        <div class="flex flex-col gap-1">
          <span class="text-xs text-muted-foreground uppercase tracking-widest">Code</span>
          <div
            bind:this={editorEl}
            class="h-64 w-full rounded-lg border border-border bg-background p-3 font-mono text-sm text-foreground overflow-auto focus:outline-none focus:ring-1 focus:ring-ring"
            contenteditable="true"
          ></div>
        </div>
      </div>

      <div>
        <button
          onclick={run}
          disabled={loading}
          class="px-4 py-2 rounded-lg border border-border bg-secondary text-foreground text-xs font-mono hover:bg-secondary/80 transition-colors disabled:opacity-50"
        >
          {loading ? 'running...' : 'run'}
        </button>
      </div>

      {#if output !== null || error !== null}
        <div class="flex flex-col gap-1">
          <span class="text-xs text-muted-foreground uppercase tracking-widest">Output</span>
          <pre class="rounded-lg border border-border p-3 text-xs font-mono overflow-auto whitespace-pre-wrap {error ? 'bg-destructive/10 text-destructive' : 'bg-secondary text-green-400'}">{error ?? output}</pre>
        </div>
      {/if}
    </div>
  </Col>
</DashboardLayout>
