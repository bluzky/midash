import { LineSeries, HistogramSeries } from 'lightweight-charts'

export function macd({ fast = 12, slow = 26, signal = 9 } = {}) {
  return {
    name: 'MACD',
    color: '#2563EB',
    warmup: slow + signal,
    panel: { height: 100, scaleId: 'macd' },
    compute(candles) {
      const closes = candles.map((c) => c.close)

      function emaArr(values, period) {
        const k = 2 / (period + 1)
        const out = new Array(values.length).fill(null)
        let prev = values.slice(0, period).reduce((a, b) => a + b, 0) / period
        out[period - 1] = prev
        for (let i = period; i < values.length; i++) {
          prev = values[i] * k + prev * (1 - k)
          out[i] = prev
        }
        return out
      }

      const ema12 = emaArr(closes, fast)
      const ema26 = emaArr(closes, slow)

      // MACD line starts at index (slow - 1)
      const macdLine = []
      const macdTimes = []
      for (let i = slow - 1; i < closes.length; i++) {
        macdLine.push(ema12[i] - ema26[i])
        macdTimes.push(candles[i].time)
      }

      const signalLine = emaArr(macdLine, signal)

      const result = []
      for (let i = signal - 1; i < macdLine.length; i++) {
        const m = macdLine[i]
        const s = signalLine[i]
        result.push({ time: macdTimes[i], macd: m, signal: s, hist: m - s })
      }
      return result
    },
    mount(chart, { scaleId = 'macd', scaleMargins = { top: 0.7, bottom: 0 } } = {}) {
      const base = { priceScaleId: scaleId, lastValueVisible: false, priceLineVisible: false }

      const histSeries = chart.addSeries(HistogramSeries, {
        ...base,
        priceFormat: { type: 'price', precision: 6, minMove: 0.000001 },
      })
      const macdSeries   = chart.addSeries(LineSeries, { ...base, color: '#2563EB', lineWidth: 1 })
      const signalSeries = chart.addSeries(LineSeries, { ...base, color: '#F97316', lineWidth: 1 })

      chart.priceScale(scaleId).applyOptions({ scaleMargins })

      return {
        setAll(data) {
          histSeries.setData(data.map((d) => ({ time: d.time, value: d.hist, color: d.hist >= 0 ? '#16a34a99' : '#dc262699' })))
          macdSeries.setData(data.map((d) => ({ time: d.time, value: d.macd })))
          signalSeries.setData(data.map((d) => ({ time: d.time, value: d.signal })))
        },
        updateLast(data) {
          for (const d of data.slice(-2)) {
            histSeries.update({ time: d.time, value: d.hist, color: d.hist >= 0 ? '#16a34a99' : '#dc262699' })
            macdSeries.update({ time: d.time, value: d.macd })
            signalSeries.update({ time: d.time, value: d.signal })
          }
        },
        setVisible(v) {
          histSeries.applyOptions({ visible: v })
          macdSeries.applyOptions({ visible: v })
          signalSeries.applyOptions({ visible: v })
        },
        destroy() {
          chart.removeSeries(histSeries)
          chart.removeSeries(macdSeries)
          chart.removeSeries(signalSeries)
        },
      }
    },
  }
}
