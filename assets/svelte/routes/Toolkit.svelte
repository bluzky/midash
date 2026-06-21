<script>
  import DashboardLayout from '../components/DashboardLayout.svelte'
  import { navigate } from '../lib/router.svelte.js'
  import { Terminal, Barcode, Globe, FileCode, Braces } from '@lucide/svelte'

  const TOOLS = [
    { id: 'elixir-execute', label: 'Elixir Execute', description: 'Run Elixir code with an input string', path: '/toolkit/elixir-execute', icon: Terminal },
    { id: 'barcode', label: 'Barcode Generator', description: 'Generate Code128 barcodes, one per line, printable 2-column grid', path: '/toolkit/barcode', icon: Barcode },
    { id: 'postbin', label: 'PostBin', description: 'Inspect HTTP requests — capture headers, query params, and body in real time', path: '/toolkit/postbin', icon: Globe },
    { id: 'mau', label: 'Mau Template', description: 'Render Mau (Liquid-inspired) templates with JSON context params', path: '/toolkit/mau', icon: FileCode },
    { id: 'map-to-json', label: 'Map → JSON', description: 'Convert Elixir map syntax to prettified JSON', path: '/toolkit/map-to-json', icon: Braces },
  ]

  let search = $state('')
  let inputEl

  let filtered = $derived(
    search === ''
      ? TOOLS
      : TOOLS.filter(
          (t) =>
            t.label.toLowerCase().includes(search.toLowerCase()) ||
            t.description.toLowerCase().includes(search.toLowerCase())
        )
  )

  function handleKeydown(e) {
    if (e.key === 'Escape') search = ''
    if (e.key === 'Enter' && filtered.length > 0) navigate(filtered[0].path)
  }

  function handleNav(e, path) {
    e.preventDefault()
    navigate(path)
  }
</script>

<DashboardLayout>
  <div class="col-span-12 flex flex-col gap-4 px-8">
    <!-- svelte-ignore a11y_autofocus -->
    <input
      bind:this={inputEl}
      bind:value={search}
      type="text"
      placeholder="search tools..."
      autofocus
      autocomplete="off"
      onkeydown={handleKeydown}
      class="w-full rounded-md border border-border bg-card px-4 py-3 font-mono text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary/20"
    />

    <div class="grid grid-cols-3 gap-3">
      {#each filtered as tool}
        <a
          href={tool.path}
          onclick={(e) => handleNav(e, tool.path)}
          class="flex items-start gap-3 rounded-lg border border-border bg-card p-4 hover:bg-secondary transition-all hover:shadow-[0_4px_16px_rgba(28,25,23,0.06)]"
        >
          <tool.icon class="w-8 h-8 text-primary shrink-0 mt-0.5" />
          <div class="flex flex-col gap-1">
            <span class="text-sm font-medium text-foreground">{tool.label}</span>
            <span class="text-xs text-muted-foreground">{tool.description}</span>
          </div>
        </a>
      {/each}

      {#if filtered.length === 0}
        <div class="col-span-3 text-center text-sm text-muted-foreground py-8">
          no tools match "{search}"
        </div>
      {/if}
    </div>
  </div>
</DashboardLayout>
