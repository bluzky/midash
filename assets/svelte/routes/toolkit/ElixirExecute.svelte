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
        class="text-xs text-muted-foreground hover:text-foreground transition-colors"
      >
        ← toolkit
      </button>
      <span class="text-xs text-muted-foreground">/</span>
      <span class="text-xs text-foreground">elixir execute</span>
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
            class="h-64 w-full rounded-md border border-border bg-card p-3 font-mono text-sm text-foreground resize-none focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary/20"
          ></textarea>
        </div>
        <div class="flex flex-col gap-1">
          <span class="text-xs text-muted-foreground uppercase tracking-widest">Code</span>
          <div
            bind:this={editorEl}
            class="h-64 w-full rounded-md border border-border bg-card p-3 font-mono text-sm text-foreground overflow-auto focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary/20"
            contenteditable="true"
          ></div>
        </div>
      </div>

      <div>
        <button
          onclick={run}
          disabled={loading}
          class="btn-primary px-4 py-2 text-xs"
        >
          {loading ? 'running...' : 'run'}
        </button>
      </div>

      {#if output !== null || error !== null}
        <div class="flex flex-col gap-1">
          <span class="text-xs text-muted-foreground uppercase tracking-widest">Output</span>
          <pre class="rounded-md border border-border p-3 text-xs font-mono overflow-auto whitespace-pre-wrap {error ? 'bg-destructive/10 text-destructive' : 'bg-secondary text-success'}">{error ?? output}</pre>
        </div>
      {/if}
    </div>
  </Col>
</DashboardLayout>
