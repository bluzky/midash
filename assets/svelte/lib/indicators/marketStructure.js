import { LineSeries } from 'lightweight-charts'

export function marketStructure({ pivot = 3 } = {}) {
  return {
    name: 'BOS/CHOCH',
    color: '#38BDF8',
    warmup: pivot * 4 + 20,
    compute(candles) {
      if (candles.length < pivot * 2 + 2) return []

      const swingHighs = []
      const swingLows = []

      for (let i = pivot; i < candles.length - pivot; i++) {
        const c = candles[i]
        let isHigh = true
        let isLow = true

        for (let j = i - pivot; j <= i + pivot; j++) {
          if (j === i) continue
          if (candles[j].high >= c.high) isHigh = false
          if (candles[j].low <= c.low) isLow = false
        }

        if (isHigh) swingHighs.push({ index: i, time: c.time, value: c.high })
        if (isLow) swingLows.push({ index: i, time: c.time, value: c.low })
      }

      const events = []
      let trend = null
      let highIdx = 0
      let lowIdx = 0
      let lastHigh = null
      let lastLow = null
      const brokenHighs = new Set()
      const brokenLows = new Set()

      for (let i = 0; i < candles.length; i++) {
        while (highIdx < swingHighs.length && swingHighs[highIdx].index < i) {
          lastHigh = swingHighs[highIdx]
          highIdx++
        }
        while (lowIdx < swingLows.length && swingLows[lowIdx].index < i) {
          lastLow = swingLows[lowIdx]
          lowIdx++
        }

        const c = candles[i]
        if (lastHigh && !brokenHighs.has(lastHigh.index) && c.close > lastHigh.value) {
          const kind = trend === 'bear' ? 'CHOCH' : 'BOS'
          events.push({ time: c.time, startTime: lastHigh.time, price: c.high, level: lastHigh.value, dir: 'bull', kind })
          brokenHighs.add(lastHigh.index)
          trend = 'bull'
        }

        if (lastLow && !brokenLows.has(lastLow.index) && c.close < lastLow.value) {
          const kind = trend === 'bull' ? 'CHOCH' : 'BOS'
          events.push({ time: c.time, startTime: lastLow.time, price: c.low, level: lastLow.value, dir: 'bear', kind })
          brokenLows.add(lastLow.index)
          trend = 'bear'
        }
      }

      return events
    },
    mount(chart) {
      const chartEl = chart.chartElement()
      const canvas = document.createElement('canvas')
      const ctx = canvas.getContext('2d')
      const coordSeries = chart.addSeries(LineSeries, { visible: false, lastValueVisible: false, priceLineVisible: false })
      let visible = true
      let latestData = []

      chartEl.style.position = chartEl.style.position || 'relative'
      canvas.style.position = 'absolute'
      canvas.style.inset = '0'
      canvas.style.pointerEvents = 'none'
      canvas.style.zIndex = '2'
      chartEl.appendChild(canvas)

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

      function draw() {
        if (!ctx) return
        const { width, height } = resizeCanvas()
        ctx.clearRect(0, 0, width, height)
        if (!visible) return

        ctx.font = '10px ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace'
        ctx.textBaseline = 'middle'

        for (const e of latestData) {
          const x = chart.timeScale().timeToCoordinate(e.time)
          const startX = chart.timeScale().timeToCoordinate(e.startTime)
          const y = coordSeries.priceToCoordinate(e.price)
          const levelY = coordSeries.priceToCoordinate(e.level)
          if (x == null || startX == null || y == null || levelY == null) continue

          const bull = e.dir === 'bull'
          const color = bull ? '#22C55E' : '#EF4444'
          const label = `${e.kind}${bull ? '↑' : '↓'}`
          const ty = Math.max(10, Math.min(height - 10, y + (bull ? -12 : 12)))

          ctx.strokeStyle = color
          ctx.fillStyle = color
          ctx.globalAlpha = 0.7
          ctx.beginPath()
          ctx.moveTo(Math.max(0, startX), levelY)
          ctx.lineTo(Math.min(width, x), levelY)
          ctx.stroke()
          ctx.globalAlpha = 1

          ctx.fillStyle = color
          ctx.textAlign = 'center'
          ctx.fillText(label, x, ty)
        }
      }

      function scheduleDraw() { requestAnimationFrame(draw) }
      chart.timeScale().subscribeVisibleLogicalRangeChange(scheduleDraw)

      return {
        setAll(data) {
          latestData = data
          coordSeries.setData(data.flatMap((d) => [
            { time: d.time, value: d.price },
            { time: d.startTime, value: d.level },
          ]))
          scheduleDraw()
        },
        updateLast(data) { this.setAll(data) },
        setVisible(v) {
          visible = v
          scheduleDraw()
        },
        destroy() {
          chart.timeScale().unsubscribeVisibleLogicalRangeChange(scheduleDraw)
          canvas.remove()
          chart.removeSeries(coordSeries)
        },
      }
    },
  }
}
