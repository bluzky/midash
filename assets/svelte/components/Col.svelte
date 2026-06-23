<script>
  let { span = 6, children } = $props();

  const spanClass = {
    3: "col-span-3 min-w-0",
    4: "col-span-4 min-w-0",
    6: "col-span-6 min-w-0",
    8: "col-span-8 min-w-0",
    9: "col-span-9 min-w-0",
    12: "col-span-12 min-w-0",
  };
</script>

<div class={spanClass[span] ?? "col-span-6 min-w-0"}>
  {@render children?.()}
</div>
