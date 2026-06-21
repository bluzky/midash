// Shared lightweight-charts theme matching the Ember Studio design system
export const baseChartOptions = {
  layout: {
    background: { color: 'transparent' },
    textColor: '#78716C',
    fontFamily: 'Roboto Mono, monospace',
    fontSize: 11,
  },
  grid: {
    horzLines: { color: '#E7E5E4' },
    vertLines: { color: '#E7E5E4' },
  },
  rightPriceScale: { borderColor: '#D6D3D1' },
  timeScale: {
    borderColor: '#D6D3D1',
    timeVisible: true,
    secondsVisible: false,
  },
  crosshair: {
    vertLine: { color: '#A8A29E' },
    horzLine: { color: '#A8A29E' },
  },
}

export const SERIES_COLORS = [
  '#C2410C', // terracotta (primary)
  '#2563EB', // blue
  '#7C3AED', // violet
  '#059669', // emerald
  '#D97706', // amber
]
