<script>
  import { SunMoon } from "@lucide/svelte";
  import { navigate, router } from "../lib/router.svelte.js";
  import { applyTheme, getStoredTheme, THEMES } from "../lib/themes.js";

  let currentTheme = $state(getStoredTheme());

  const pages = [
    { id: "work", label: "work", path: "/work" },
    { id: "monitor", label: "monitor", path: "/monitor" },
    { id: "argocd", label: "argocd", path: "/argocd" },
    { id: "toolkit", label: "toolkit", path: "/toolkit" },
    { id: "crypto", label: "crypto", path: "/crypto" },
  ];

  function isActive(path) {
    return router.path === path || router.path.startsWith(path + "/");
  }

  function handleNav(e, path) {
    e.preventDefault();
    navigate(path);
  }

  function handleTheme(id) {
    applyTheme(id);
    currentTheme = id;
  }
</script>

<nav
  class="fixed top-0 inset-x-0 z-50 flex items-center gap-1 bg-background/90 backdrop-blur px-4 py-2"
>
  <img src="/images/logo.svg" alt="midash" class="h-5 mr-2" />

  {#each pages as page}
    <a
      href={page.path}
      onclick={(e) => handleNav(e, page.path)}
      class="px-3 py-1.5 text-sm rounded-md transition-colors font-medium uppercase tracking-wide {isActive(
        page.path,
      )
        ? 'bg-primary/10 text-primary'
        : 'text-muted-foreground hover:text-foreground hover:bg-secondary'}"
    >
      {page.label}
    </a>
  {/each}

  <div class="ml-auto flex items-center gap-2 pl-3">
    {#each THEMES as theme}
      {#if theme.id === "system"}
        <button
          onclick={() => handleTheme("system")}
          title="System"
          class="rounded-md p-0.5 transition-all duration-150 {currentTheme ===
          'system'
            ? 'text-primary'
            : 'text-muted-foreground opacity-50 hover:opacity-100'}"
        >
          <SunMoon class="w-3.5 h-3.5" />
        </button>
      {:else}
        <button
          onclick={() => handleTheme(theme.id)}
          title={theme.label}
          class="w-3.5 h-3.5 rounded-full transition-all duration-150 {currentTheme ===
          theme.id
            ? 'ring-2 ring-offset-2 ring-offset-background ring-primary scale-125'
            : 'opacity-50 hover:opacity-100 hover:scale-110'}"
          style="background-color: {theme.color}"
        ></button>
      {/if}
    {/each}
  </div>
</nav>
