<script>
  import { Sun, Moon } from '@lucide/svelte'
  import { navigate, router } from '../lib/router.svelte.js'
  import { applyTheme, getStoredTheme } from '../lib/themes.js'

  let currentTheme = $state(getStoredTheme())

  const pages = [
    { id: 'home', label: 'home', path: '/' },
    { id: 'work', label: 'work', path: '/work' },
    { id: 'monitor', label: 'monitor', path: '/monitor' },
    { id: 'argocd', label: 'argocd', path: '/argocd' },
    { id: 'toolkit', label: 'toolkit', path: '/toolkit' },
    { id: 'crypto', label: 'crypto', path: '/crypto' },
  ]

  function isActive(path) {
    if (path === '/') return router.path === '/'
    return router.path.startsWith(path)
  }

  function handleNav(e, path) {
    e.preventDefault()
    navigate(path)
  }

  function toggleTheme() {
    const next = currentTheme === 'dark' ? 'light' : 'dark'
    applyTheme(next)
    currentTheme = next
  }
</script>

<nav class="fixed top-0 inset-x-0 z-50 flex items-center gap-1 border-b border-border bg-background px-4 py-2">
  <img src="/images/logo.svg" alt="midash" class="h-5 mr-2" />

  {#each pages as page}
    <a
      href={page.path}
      onclick={(e) => handleNav(e, page.path)}
      class="px-3 py-1.5 text-sm rounded-md transition-colors {isActive(page.path)
        ? 'bg-secondary text-foreground'
        : 'text-muted-foreground hover:text-foreground hover:bg-secondary/50'}"
    >
      {page.label}
    </a>
  {/each}

  <button
    onclick={toggleTheme}
    class="ml-auto rounded-sm p-1.5 text-muted-foreground hover:text-foreground hover:bg-secondary transition-colors"
    title="toggle theme"
  >
    {#if currentTheme === 'dark'}
      <Sun class="w-4 h-4" />
    {:else}
      <Moon class="w-4 h-4" />
    {/if}
  </button>
</nav>
