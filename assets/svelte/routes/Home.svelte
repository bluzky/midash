<script>
  import DashboardLayout from '../components/DashboardLayout.svelte'
  import Col from '../components/Col.svelte'
  import Widget from '../components/Widget.svelte'
  import WorldClock from '../widgets/WorldClock.svelte'
</script>

<DashboardLayout>
  <Col span={3}>
    <Widget title="world clock" collapsible>
      <WorldClock />
    </Widget>

    <Widget title="bookmarks" collapsible>
      <p class="text-sm text-muted-foreground italic">your bookmarks</p>
    </Widget>
  </Col>

  <Col span={6}>
    <Widget title="notes" collapsible>
      <p class="text-sm text-muted-foreground italic">your notes widget goes here</p>
    </Widget>

    <Widget title="hacker news" collapsible>
      <p class="text-sm text-muted-foreground italic">hacker news feed</p>
    </Widget>
  </Col>

  <Col span={3}>
    <Widget title="markets" collapsible>
      <p class="text-sm text-muted-foreground italic">market tickers</p>
    </Widget>

    <Widget title="rss" collapsible>
      <p class="text-sm text-muted-foreground italic">rss feeds</p>
    </Widget>
  </Col>
</DashboardLayout>
