import { LineSeries } from 'lightweight-charts'

export function ema({ period = 9, color = '#EAB308' } = {}) {
  return {
    warmup: period,
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
        update(data) { series.setData(data) },
        destroy() { chart.removeSeries(series) },
      }
    },
  }
}
