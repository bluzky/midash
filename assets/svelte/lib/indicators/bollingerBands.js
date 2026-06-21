import { LineSeries } from 'lightweight-charts'

export function bollingerBands({ period = 20, mult = 2 } = {}) {
  return {
    name: 'BB',
    color: '#EAB308',
    warmup: period,
    compute(candles) {
      const bands = []
      for (let i = period - 1; i < candles.length; i++) {
        const closes = candles.slice(i - period + 1, i + 1).map((c) => c.close)
        const mean = closes.reduce((a, b) => a + b, 0) / period
        const std = Math.sqrt(closes.reduce((s, v) => s + (v - mean) ** 2, 0) / period)
        bands.push({ time: candles[i].time, upper: mean + mult * std, middle: mean, lower: mean - mult * std })
      }
      return bands
    },
    mount(chart) {
      const style = { lineWidth: 1, lastValueVisible: false, priceLineVisible: false }
      const upper  = chart.addSeries(LineSeries, { ...style, color: '#EAB308' })
      const middle = chart.addSeries(LineSeries, { ...style, color: '#8B5CF6' })
      const lower  = chart.addSeries(LineSeries, { ...style, color: '#8B5CF6' })
      return {
        setAll(bands) {
          upper.setData(bands.map((b) => ({ time: b.time, value: b.upper })))
          middle.setData(bands.map((b) => ({ time: b.time, value: b.middle })))
          lower.setData(bands.map((b) => ({ time: b.time, value: b.lower })))
        },
        updateLast(bands) {
          for (const b of bands.slice(-2)) {
            upper.update({ time: b.time, value: b.upper })
            middle.update({ time: b.time, value: b.middle })
            lower.update({ time: b.time, value: b.lower })
          }
        },
        setVisible(v) {
          upper.applyOptions({ visible: v })
          middle.applyOptions({ visible: v })
          lower.applyOptions({ visible: v })
        },
        destroy() {
          chart.removeSeries(upper)
          chart.removeSeries(middle)
          chart.removeSeries(lower)
        },
      }
    },
  }
}
