<script>
  import { createChart, AreaSeries } from "lightweight-charts";
  import { baseChartOptions, SERIES_COLORS } from "../../lib/chart-theme.js";

  let { data, config = {} } = $props();
  let series = $derived(data?.series ?? []);
  let height = $derived(config.height ?? 200);
  let emptyMessage = $derived(config.emptyMessage ?? "no data");

  function hexToRgba(hex, alpha) {
    const r = parseInt(hex.slice(1, 3), 16);
    const g = parseInt(hex.slice(3, 5), 16);
    const b = parseInt(hex.slice(5, 7), 16);
    return `rgba(${r}, ${g}, ${b}, ${alpha})`;
  }

  function areaChart(node, params) {
    const chart = createChart(node, {
      ...baseChartOptions,
      width: node.clientWidth,
      height,
    });

    const instances = params.series.map((s, i) => {
      const color = s.color ?? SERIES_COLORS[i % SERIES_COLORS.length];
      const inst = chart.addSeries(AreaSeries, {
        lineColor: color,
        topColor: hexToRgba(color, 0.3),
        bottomColor: hexToRgba(color, 0.02),
        lineWidth: 2,
        title: s.name ?? "",
      });
      inst.setData(s.data ?? []);
      return inst;
    });

    const ro = new ResizeObserver(() => chart.resize(node.clientWidth, height));
    ro.observe(node);

    return {
      update(p) {
        p.series.forEach((s, i) => instances[i]?.setData(s.data ?? []));
      },
      destroy() {
        ro.disconnect();
        chart.remove();
      },
    };
  }
</script>

{#if !series.length}
  <div class="text-muted-foreground text-sm">{emptyMessage}</div>
{:else}
  <div use:areaChart={{ series }}></div>
{/if}
