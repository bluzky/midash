<script>
  import { createChart, LineSeries } from 'lightweight-charts'
  import { baseChartOptions, SERIES_COLORS } from '../../lib/chart-theme.js'

  let { data, config = {} } = $props()
  const { series = [] } = data ?? {}
  const { height = 200, emptyMessage = 'no data' } = config

  function lineChart(node, params) {
    const chart = createChart(node, { ...baseChartOptions, width: node.clientWidth, height })

    const instances = params.series.map((s, i) => {
      const color = s.color ?? SERIES_COLORS[i % SERIES_COLORS.length]
      const inst = chart.addSeries(LineSeries, { color, lineWidth: 2, title: s.name ?? '' })
      inst.setData(s.data ?? [])
      return inst
    })

    const ro = new ResizeObserver(() => chart.resize(node.clientWidth, height))
    ro.observe(node)

    return {
      update(p) {
        p.series.forEach((s, i) => instances[i]?.setData(s.data ?? []))
      },
      destroy() {
        ro.disconnect()
        chart.remove()
      },
    }
  }
</script>

{#if !series.length}
  <div class="text-muted-foreground text-sm">{emptyMessage}</div>
{:else}
  <div use:lineChart={{ series }}></div>
{/if}
