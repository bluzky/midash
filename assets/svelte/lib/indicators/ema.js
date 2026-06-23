import { LineSeries } from 'lightweight-charts'

export function ema({ period = 9, color = '#EAB308' } = {}) {
  return {
    name: `EMA ${period}`,
    color,
    warmup: period,
    valueLabel(data, time = null) {
      const point = time == null ? data.at(-1) : data.find((d) => d.time === time)
      const value = point?.value
      if (value == null) return null
      return `${this.name}(${value.toFixed(value >= 100 ? 2 : 4)})`
    },
    compute(candles) {
      if (candles.length < period) return []
      const k = 2 / (period + 1)
      const result = []
      // Seed with SMA of first `period` candles
      let prev = candles.slice(0, period).reduce((s, c) => s + c.close, 0) / period
      result.push({ time: candles[period - 1].time, value: prev })
      for (let i = period; i < candles.length; i++) {
        prev = candles[i].close * k + prev * (1 - k)
        result.push({ time: candles[i].time, value: prev })
      }
      return result
    },
    mount(chart) {
      const series = chart.addSeries(LineSeries, {
        color,
        lineWidth: 1,
        lastValueVisible: false,
        priceLineVisible: false,
      })
      return {
        setAll(data) { series.setData(data) },
        updateLast(data) {
          for (const d of data.slice(-2)) series.update(d)
        },
        setVisible(v) { series.applyOptions({ visible: v }) },
        destroy() { chart.removeSeries(series) },
      }
    },
  }
}
