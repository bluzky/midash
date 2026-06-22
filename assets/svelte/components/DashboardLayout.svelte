<script>
  import Nav from './Nav.svelte'

  let { children } = $props()
</script>

<div class="min-h-screen bg-background text-foreground">
  <Nav />
  <div class="grid grid-cols-12 gap-4 px-4 pb-6 items-start mt-[36px]">
    {@render children?.()}
  </div>
</div>
