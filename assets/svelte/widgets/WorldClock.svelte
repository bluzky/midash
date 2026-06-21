<script>
  const DEFAULT_CLOCKS = [
    { label: 'Phoenix', tz: 'America/Phoenix' },
    { label: 'Singapore', tz: 'Asia/Singapore' },
    { label: 'Tokyo', tz: 'Asia/Tokyo' },
  ]

  let { clocks = DEFAULT_CLOCKS } = $props()
  let times = $state([])

  function formatTime(tz) {
    return new Intl.DateTimeFormat('en-US', {
      timeZone: tz,
      hour: '2-digit',
      minute: '2-digit',
      hour12: true,
    }).format(new Date())
  }

  function tick() {
    times = clocks.map((c) => ({ label: c.label, time: formatTime(c.tz) }))
  }

  tick()
  const interval = setInterval(tick, 1000)
  $effect(() => () => clearInterval(interval))
</script>

<div class="space-y-3">
  {#each times as { label, time }}
    <div class="flex items-baseline justify-between gap-2">
      <span class="text-xs text-muted-foreground truncate">{label}</span>
      <span class="text-sm tabular-nums text-foreground font-mono tracking-tight">{time}</span>
    </div>
  {/each}
</div>
