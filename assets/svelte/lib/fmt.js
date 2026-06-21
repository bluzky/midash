export function relTime(iso) {
  const diff = Math.floor((Date.now() - new Date(iso)) / 3600000)
  if (diff < 1) return 'just now'
  if (diff < 24) return `${diff}h ago`
  return `${Math.floor(diff / 24)}d ago`
}

export function relTimeSec(iso) {
  const diff = Math.floor((Date.now() - new Date(iso)) / 1000)
  if (diff < 60) return 'now'
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`
  if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`
  if (diff < 604800) return `${Math.floor(diff / 86400)}d ago`
  return `${Math.floor(diff / 604800)}w ago`
}

export function fmtCount(n) {
  const c = parseInt(n)
  if (c >= 1_000_000) return (c / 1_000_000).toFixed(1) + 'M'
  if (c >= 1000) return (c / 1000).toFixed(1) + 'K'
  return String(c)
}

export function fmtPrice(p) {
  if (p == null) return '—'
  return p >= 1000 ? '$' + Math.round(p).toLocaleString() : '$' + p.toFixed(2)
}

export function fmtRate(r) {
  if (r == null) return '—'
  return (r >= 0 ? '+' : '') + (r * 100).toFixed(4) + '%'
}

export function fmtAnnualized(r) {
  if (r == null) return '—'
  return (r >= 0 ? '+' : '') + (r * 3 * 100).toFixed(4) + '% 24h'
}

export function fmtChange(v) {
  if (v == null) return '—'
  return (v >= 0 ? '+' : '') + v.toFixed(2) + '%'
}

export function fmtOI(v) {
  if (v == null) return '—'
  if (v >= 1_000_000) return (v / 1_000_000).toFixed(2) + 'M'
  if (v >= 1_000) return (v / 1_000).toFixed(1) + 'K'
  return v.toFixed(0)
}

export function fmtCountdown(ms) {
  if (!ms) return '—'
  const diff = Math.floor((ms - Date.now()) / 1000)
  if (diff <= 0) return 'now'
  if (diff < 3600) return `${Math.floor(diff / 60)}m ${diff % 60}s`
  return `${Math.floor(diff / 3600)}h ${Math.floor((diff % 3600) / 60)}m`
}

export function fmtDue(ms) {
  if (!ms) return ''
  const diff = Math.floor((new Date(parseInt(ms)) - Date.now()) / 3600000)
  if (diff < 0) return 'overdue'
  if (diff < 24) return 'today'
  if (diff < 48) return 'tomorrow'
  return `${Math.floor(diff / 24)}d`
}
