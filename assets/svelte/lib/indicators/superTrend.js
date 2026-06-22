import { LineSeries } from 'lightweight-charts'

export function superTrend({ period = 10, multiplier = 3 } = {}) {
  return {
    name: `ST ${period}`,
    color: '#10B981',
    warmup: Math.max(period * 10, 100),
    compute(candles) {
      if (candles.length < period + 1) return []

      // True range for each candle starting at index 1
      // tr[i] belongs to candles[i+1]
      const tr = []
      for (let i = 1; i < candles.length; i++) {
        const h = candles[i].high, l = candles[i].low, pc = candles[i - 1].close
        tr.push(Math.max(h - l, Math.abs(h - pc), Math.abs(l - pc)))
      }

      // Wilder's ATR (RMA) — atr[i] belongs to candles[i+1]
      const atr = new Array(tr.length).fill(null)
      atr[period - 1] = tr.slice(0, period).reduce((s, v) => s + v, 0) / period
      for (let i = period; i < tr.length; i++) {
        atr[i] = (atr[i - 1] * (period - 1) + tr[i]) / period
      }

      const result = []
      let prevUpper = null, prevLower = null, prevBullish = null, prevClose = null

      for (let ci = period; ci < candles.length; ci++) {
        const atrVal = atr[ci - 1]
        const hl2 = (candles[ci].high + candles[ci].low) / 2
        const basicUpper = hl2 + multiplier * atrVal
        const basicLower = hl2 - multiplier * atrVal

        const finalUpper = prevUpper == null || basicUpper < prevUpper || prevClose > prevUpper ? basicUpper : prevUpper
        const finalLower = prevLower == null || basicLower > prevLower || prevClose < prevLower ? basicLower : prevLower

        let bullish
        if (prevBullish == null) {
          bullish = candles[ci].close > finalUpper
        } else if (!prevBullish) {
          bullish = candles[ci].close > finalUpper
        } else {
          bullish = candles[ci].close >= finalLower
        }

        result.push({
          time: candles[ci].time,
          value: bullish ? finalLower : finalUpper,
          mid: (candles[ci].open + candles[ci].close) / 2,
          bullish,
        })

        prevUpper = finalUpper
        prevLower = finalLower
        prevBullish = bullish
        prevClose = candles[ci].close
      }

      return result
    },
    mount(chart) {
      const base = { lineWidth: 2, lastValueVisible: false, priceLineVisible: false }
      const chartEl = chart.chartElement()
      const canvas = document.createElement('canvas')
      const ctx = canvas.getContext('2d')
      let series = []
      let visible = true
      let latestData = []

      chartEl.style.position = chartEl.style.position || 'relative'
      canvas.style.position = 'absolute'
      canvas.style.inset = '0'
      canvas.style.pointerEvents = 'none'
      canvas.style.zIndex = '1'
      chartEl.appendChild(canvas)

      function segment(data) {
        const segments = []
        let current = []
        let currentBullish = null

        for (let i = 0; i < data.length; i++) {
          const d = data[i]
          const point = { time: d.time, value: d.value, mid: d.mid }

          if (currentBullish === null) {
            currentBullish = d.bullish
            current = [point]
            continue
          }

          if (d.bullish === currentBullish) {
            current.push(point)
          } else {
            if (current.length) segments.push({ bullish: currentBullish, data: current })
            currentBullish = d.bullish
            current = [point]
          }
        }

        if (current.length) segments.push({ bullish: currentBullish, data: current })
        return segments
      }

      function clear() {
        for (const s of series) chart.removeSeries(s)
        series = []
      }

      function resizeCanvas() {
        const { width, height } = chart.paneSize(0)
        const dpr = window.devicePixelRatio || 1
        canvas.style.width = `${width}px`
        canvas.style.height = `${height}px`
        canvas.width = Math.floor(width * dpr)
        canvas.height = Math.floor(height * dpr)
        ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
        return { width, height }
      }

      function drawFill() {
        if (!ctx) return
        const { width, height } = resizeCanvas()
        ctx.clearRect(0, 0, width, height)
        if (!visible || !series[0]) return

        for (const seg of segment(latestData)) {
          const points = seg.data
            .map((d) => ({
              x: chart.timeScale().timeToCoordinate(d.time),
              stY: series[0].priceToCoordinate(d.value),
              midY: series[0].priceToCoordinate(d.mid),
            }))
            .filter((p) => p.x != null && p.stY != null && p.midY != null)

          if (points.length < 2) continue

          ctx.beginPath()
          ctx.moveTo(points[0].x, points[0].stY)
          for (const p of points.slice(1)) ctx.lineTo(p.x, p.stY)
          for (const p of points.slice().reverse()) ctx.lineTo(p.x, p.midY)
          ctx.closePath()
          ctx.fillStyle = seg.bullish ? 'rgba(16, 185, 129, 0.10)' : 'rgba(239, 68, 68, 0.10)'
          ctx.fill()
        }
      }

      function scheduleFill() {
        requestAnimationFrame(drawFill)
      }

      function render(data) {
        latestData = data
        clear()
        for (const seg of segment(data)) {
          const s = chart.addSeries(LineSeries, {
            ...base,
            color: seg.bullish ? '#10B981' : '#EF4444',
            visible,
          })
          s.setData(seg.data.map((d) => ({ time: d.time, value: d.value })))
          series.push(s)
        }
        scheduleFill()
      }

      chart.timeScale().subscribeVisibleLogicalRangeChange(scheduleFill)

      return {
        setAll(data) {
          render(data)
        },
        updateLast(data) {
          render(data)
        },
        setVisible(v) {
          visible = v
          series.forEach((s) => s.applyOptions({ visible }))
          scheduleFill()
        },
        destroy() {
          chart.timeScale().unsubscribeVisibleLogicalRangeChange(scheduleFill)
          canvas.remove()
          clear()
        },
      }
    },
  }
}
