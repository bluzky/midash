<script>
  import DashboardLayout from '../../components/DashboardLayout.svelte'
  import Col from '../../components/Col.svelte'
  import { navigate } from '../../lib/router.svelte.js'
  import { post } from '../../lib/api.js'

  let input = $state('')
  let barcodes = $state([])
  let loading = $state(false)

  async function generate() {
    const codes = input.split('\n').map((l) => l.trim()).filter(Boolean)
    if (!codes.length) return
    loading = true
    try {
      const res = await post('/api/toolkit/barcode', { codes })
      barcodes = res.data
    } finally {
      loading = false
    }
  }
</script>

<DashboardLayout>
  <Col span={12}>
    <div class="mb-3 flex items-center gap-3">
      <button onclick={() => navigate('/toolkit')} class="text-sm text-muted-foreground hover:text-foreground transition-colors">← toolkit</button>
      <span class="text-sm text-muted-foreground">/</span>
      <span class="text-sm text-foreground">barcode generator</span>
    </div>

    <div class="flex flex-col gap-4">
      <div class="flex flex-col gap-2">
        <label for="barcode-input" class="text-xs text-muted-foreground uppercase tracking-widest">Barcodes (one per line)</label>
        <textarea
          id="barcode-input"
          bind:value={input}
          rows="6"
          placeholder="ABC-001&#10;ABC-002&#10;ABC-003"
          class="w-full rounded-md border border-border bg-card p-3 font-mono text-sm text-foreground resize-y focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary/20"
        ></textarea>
        <div class="flex items-center gap-3">
          <button
            onclick={generate}
            disabled={loading}
            class="btn-primary px-4 py-2 capitalize"
          >
            {loading ? 'generating...' : 'generate'}
          </button>
          {#if barcodes.length}
            <button
              onclick={() => window.print()}
              class="px-4 py-2 rounded-md border border-border text-foreground font-medium hover:bg-secondary transition-colors capitalize"
            >
              print
            </button>
          {/if}
        </div>
      </div>

      {#if barcodes.length}
        <div class="grid grid-cols-2 gap-4 print:gap-2" id="barcode-grid">
          {#each barcodes as b}
            <div class="flex flex-col items-center justify-center gap-1 rounded-lg border border-border bg-card p-4">
              {#if b.error}
                <div class="text-xs text-destructive font-mono">{b.value}: {b.error}</div>
              {:else}
                <div class="[&_svg]:max-w-full [&_svg]:h-auto">{@html b.svg}</div>
                <span class="text-xs font-mono text-foreground">{b.value}</span>
              {/if}
            </div>
          {/each}
        </div>
      {/if}
    </div>
  </Col>
</DashboardLayout>
