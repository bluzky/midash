<script>
  import DashboardLayout from '../components/DashboardLayout.svelte'
  import Col from '../components/Col.svelte'
  import Widget from '../components/Widget.svelte'
  import CryptoChart from '../widgets/CryptoChart.svelte'
  import CryptoFunding from '../widgets/CryptoFunding.svelte'

  let mainChart, altChart, funding
</script>

<DashboardLayout>
  <Col span={4}>
    <Widget title="ETH / BTC" collapsible onRefresh={() => mainChart?.refresh()}>
      <CryptoChart bind:this={mainChart} symbols={['ETHUSDT', 'BTCUSDT']} />
    </Widget>
  </Col>

  <Col span={4}>
    <Widget title="others" collapsible onRefresh={() => altChart?.refresh()}>
      <CryptoChart bind:this={altChart} symbols={['ZECUSDC', 'HYPEUSDT']} />
    </Widget>
  </Col>

  <Col span={4}>
    <Widget title="funding rate & open interest" collapsible onRefresh={() => funding?.refresh()}>
      <CryptoFunding bind:this={funding} />
    </Widget>
  </Col>
</DashboardLayout>
