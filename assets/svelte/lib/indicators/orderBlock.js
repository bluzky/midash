import { LineSeries } from "lightweight-charts";

export function orderBlock({
  pivot = 2,
  lookback = 5,
  extendBars = 20,
  maxBlocks = 20,
} = {}) {
  return {
    name: "Order Block",
    color: "#A78BFA",
    warmup: pivot * 4 + lookback + 30,
    compute(candles) {
      if (candles.length < pivot * 2 + 3) return [];

      const pivotHigh = new Map();
      const pivotLow = new Map();

      for (let i = pivot; i < candles.length - pivot; i++) {
        const c = candles[i];
        let isHigh = true;
        let isLow = true;
        for (let j = i - pivot; j <= i + pivot; j++) {
          if (j === i) continue;
          if (candles[j].high >= c.high) isHigh = false;
          if (candles[j].low <= c.low) isLow = false;
        }
        // Pine pivots are confirmed `pivot` bars later.
        if (isHigh) pivotHigh.set(i + pivot, c.high);
        if (isLow) pivotLow.set(i + pivot, c.low);
      }

      const blocks = [];
      let lastSwingHigh = null;
      let lastSwingLow = null;
      let prevClose = null;

      function addBlock(dir, breakIndex) {
        const wantBearish = dir === "bull";
        let obIndex = 1;
        let extreme = wantBearish
          ? candles[breakIndex - 1]?.low
          : candles[breakIndex - 1]?.high;

        for (let barsBack = 1; barsBack <= lookback; barsBack++) {
          const idx = breakIndex - barsBack;
          if (idx < 0) break;
          const c = candles[idx];

          if (wantBearish) {
            if (c.close < c.open && c.low <= extreme) {
              extreme = c.low;
              obIndex = barsBack;
              break;
            }
          } else if (c.close > c.open && c.high >= extreme) {
            extreme = c.high;
            obIndex = barsBack;
            break;
          }
        }

        const idx = breakIndex - obIndex;
        const ob = candles[idx];
        if (!ob) return;

        const top = ob.high;
        const bottom = ob.low;
        const mitigated = candles
          .slice(breakIndex + 1)
          .some((c) => (dir === "bull" ? c.low <= top : c.high >= bottom));
        if (mitigated) return;

        blocks.push({
          dir,
          start: ob.time,
          breakTime: candles[breakIndex].time,
          end: candles[breakIndex + extendBars]?.time ?? null,
          extendBars,
          top,
          bottom,
        });
      }

      for (let i = 0; i < candles.length; i++) {
        if (pivotHigh.has(i)) lastSwingHigh = pivotHigh.get(i);
        if (pivotLow.has(i)) lastSwingLow = pivotLow.get(i);

        const c = candles[i];
        const c1 = candles[i - 1];
        const c2 = candles[i - 2];
        if (!c1 || !c2) {
          prevClose = c.close;
          continue;
        }

        const bullishBos =
          lastSwingHigh != null &&
          prevClose != null &&
          prevClose <= lastSwingHigh &&
          c.close > lastSwingHigh;
        const bearishBos =
          lastSwingLow != null &&
          prevClose != null &&
          prevClose >= lastSwingLow &&
          c.close < lastSwingLow;
        const bullishFvg = c.low > c2.high && c1.close > c2.high;
        const bearishFvg = c.high < c2.low && c1.close < c2.low;

        if (bullishBos && bullishFvg) addBlock("bull", i);
        if (bearishBos && bearishFvg) addBlock("bear", i);

        prevClose = c.close;
      }

      return blocks.slice(-maxBlocks);
    },
    mount(chart) {
      const chartEl = chart.chartElement();
      const canvas = document.createElement("canvas");
      const ctx = canvas.getContext("2d");
      const coordSeries = chart.addSeries(LineSeries, {
        visible: false,
        lastValueVisible: false,
        priceLineVisible: false,
      });
      let visible = true;
      let latestData = [];

      chartEl.style.position = chartEl.style.position || "relative";
      canvas.style.position = "absolute";
      canvas.style.inset = "0";
      canvas.style.pointerEvents = "none";
      canvas.style.zIndex = "0";
      chartEl.appendChild(canvas);

      function resizeCanvas() {
        const { width, height } = chart.paneSize(0);
        const dpr = window.devicePixelRatio || 1;
        canvas.style.width = `${width}px`;
        canvas.style.height = `${height}px`;
        canvas.width = Math.floor(width * dpr);
        canvas.height = Math.floor(height * dpr);
        ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
        return { width, height };
      }

      function barPx(width) {
        const range = chart.timeScale().getVisibleLogicalRange?.();
        if (!range) return 6;
        return width / Math.max(1, range.to - range.from);
      }

      function draw() {
        if (!ctx) return;
        const { width, height } = resizeCanvas();
        ctx.clearRect(0, 0, width, height);
        if (!visible) return;

        const px = barPx(width);
        for (const b of latestData) {
          const x1 = chart.timeScale().timeToCoordinate(b.start);
          const breakX = chart.timeScale().timeToCoordinate(b.breakTime);
          const endX = b.end ? chart.timeScale().timeToCoordinate(b.end) : null;
          const y1 = coordSeries.priceToCoordinate(b.top);
          const y2 = coordSeries.priceToCoordinate(b.bottom);
          if (x1 == null || breakX == null || y1 == null || y2 == null)
            continue;

          const x2 = endX ?? breakX + px * b.extendBars;
          const bull = b.dir === "bull";
          const left = Math.max(0, Math.min(x1, x2));
          const right = Math.min(width, Math.max(x1, x2));
          const top = Math.max(0, Math.min(y1, y2));
          const bottom = Math.min(height, Math.max(y1, y2));
          if (right <= 0 || left >= width || bottom <= top) continue;

          ctx.fillStyle = bull
            ? "rgba(34, 197, 94, 0.10)"
            : "rgba(239, 68, 68, 0.10)";
          ctx.strokeStyle = bull
            ? "rgba(34, 197, 94, 0.45)"
            : "rgba(239, 68, 68, 0.45)";
          ctx.fillRect(left, top, right - left, bottom - top);
          ctx.strokeRect(left, top, right - left, bottom - top);
        }
      }

      function scheduleDraw() {
        requestAnimationFrame(draw);
      }
      chart.timeScale().subscribeVisibleLogicalRangeChange(scheduleDraw);

      return {
        setAll(data) {
          latestData = data;
          coordSeries.setData(
            data.flatMap((b) => [
              { time: b.start, value: b.top },
              { time: b.breakTime, value: b.bottom },
            ]),
          );
          scheduleDraw();
        },
        updateLast(data) {
          this.setAll(data);
        },
        setVisible(v) {
          visible = v;
          scheduleDraw();
        },
        destroy() {
          chart.timeScale().unsubscribeVisibleLogicalRangeChange(scheduleDraw);
          canvas.remove();
          chart.removeSeries(coordSeries);
        },
      };
    },
  };
}
