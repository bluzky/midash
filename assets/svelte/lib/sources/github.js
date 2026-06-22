import { get } from '../api.js'
import { relTime } from '../fmt.js'

export function githubMyPRs({ repos = [] } = {}) {
  return async () => {
    const qs = repos.map((r) => `repos[]=${encodeURIComponent(r)}`).join('&')
    const res = await get(`/api/github/my-prs?${qs}`)
    const tabs = repos.map((repo) => {
      const key = repo.split('/').at(-1)
      const d = res.data[repo]
      const items = (d?.prs ?? []).map((pr) => ({
        title: `#${pr.number} ${pr.title}`,
        subtitle: pr.head_ref ?? null,
        badge: pr.approvals > 0 ? `${pr.approvals} ✓` : null,
        badgeVariant: pr.approvals > 0 ? 'success' : 'default',
        href: pr.html_url,
        meta: relTime(pr.created_at),
      }))
      return { key, label: key, count: items.length, items, emptyMessage: 'no open prs' }
    })
    return { tabs }
  }
}

// Returns pivot table: one row per author, one column per repo
export function githubPRs({ repos = [] } = {}) {
  return async () => {
    const qs = repos.map((r) => `repos[]=${encodeURIComponent(r)}`).join('&')
    const res = await get(`/api/github/prs?${qs}`)

    const repoKeys = repos.map((r) => ({ key: r.split('/').at(-1), full: r }))

    // Build author → repoKey → count map
    const authorMap = {}
    for (const [fullRepo, d] of Object.entries(res.data)) {
      if (d.error || !d.prs?.length) continue
      const key = fullRepo.split('/').at(-1)
      for (const pr of d.prs) {
        if (!authorMap[pr.author]) authorMap[pr.author] = {}
        authorMap[pr.author][key] = (authorMap[pr.author][key] ?? 0) + 1
      }
    }

    const rows = Object.entries(authorMap).map(([author, counts]) => {
      const row = { author }
      for (const { key, full } of repoKeys) {
        const n = counts[key] ?? 0
        row[key] = n > 0
          ? { text: String(n), badge: true, href: `https://github.com/${full}/pulls?q=is:pr+is:open+author:${author}` }
          : null
      }
      return row
    })

    // Sort by total open PRs descending
    rows.sort((a, b) => {
      const tot = (r) => repoKeys.reduce((s, { key }) => s + (r[key] ? parseInt(r[key].text) : 0), 0)
      return tot(b) - tot(a)
    })

    return {
      columns: [
        { key: 'author', label: 'author' },
        ...repoKeys.map(({ key }) => ({ key, label: key, align: 'center', width: '80px' })),
      ],
      rows,
    }
  }
}

export function githubPendingReview({ repos = [] } = {}) {
  return async () => {
    const qs = repos.map((r) => `repos[]=${encodeURIComponent(r)}`).join('&')
    const res = await get(`/api/github/pending-review?${qs}`)
    const tabs = repos.map((repo) => {
      const key = repo.split('/').at(-1)
      const d = res.data[repo]
      const items = (d?.prs ?? []).map((pr) => ({
        title: `#${pr.number} ${pr.title}`,
        subtitle: pr.author,
        href: pr.html_url,
        meta: relTime(pr.created_at),
      }))
      return { key, label: key, count: items.length, items, emptyMessage: 'no pending reviews' }
    })
    return { tabs }
  }
}
