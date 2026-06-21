<script>
  import Nav from './Nav.svelte'

  let { children } = $props()
</script>

<div class="min-h-screen bg-background text-foreground">
  <Nav />
  <div class="grid grid-cols-12 gap-4 px-4 py-6 items-start pt-[calc(36px+1.5rem)]">
    {@render children?.()}
  </div>
</div>
