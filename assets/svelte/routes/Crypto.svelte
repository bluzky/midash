<script>
  import DashboardLayout from '../components/DashboardLayout.svelte'
  import Col from '../components/Col.svelte'
  import Widget from '../components/Widget.svelte'
  import CryptoChart from '../widgets/CryptoChart.svelte'

  const SYMBOLS = ['ETHUSDT', 'BTCUSDT', 'ZECUSDC', 'HYPEUSDT']
  let widgets = $state({})
</script>

<DashboardLayout>
  {#each SYMBOLS as sym}
    <Col span={6}>
      <Widget title={sym} collapsible onRefresh={() => widgets[sym]?.refresh()}>
        <CryptoChart bind:this={widgets[sym]} symbol={sym} />
      </Widget>
    </Col>
  {/each}
</DashboardLayout>
