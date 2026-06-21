import { get } from '../api.js'
import { relTime } from '../fmt.js'

export function githubMyPRs({ repos = [] } = {}) {
  return async () => {
    const qs = repos.map((r) => `repos[]=${encodeURIComponent(r)}`).join('&')
    const res = await get(`/api/github/my-prs?${qs}`)
    const items = Object.values(res.data).flatMap((d) => {
      if (d.error || !d.prs?.length) return []
      return d.prs.map((pr) => ({
        title: `#${pr.number} ${pr.title}`,
        subtitle: pr.head_ref ?? null,
        badge: pr.approvals > 0 ? `${pr.approvals} ✓` : null,
        badgeVariant: pr.approvals > 0 ? 'success' : 'default',
        href: pr.html_url,
        meta: relTime(pr.created_at),
      }))
    })
    return { items }
  }
}

// Returns table shape: one row per author per repo, sorted by PR count
export function githubPRs({ repos = [] } = {}) {
  return async () => {
    const qs = repos.map((r) => `repos[]=${encodeURIComponent(r)}`).join('&')
    const res = await get(`/api/github/prs?${qs}`)
    const rows = []
    for (const [repo, d] of Object.entries(res.data)) {
      if (d.error || !d.prs?.length) continue
      const repoName = repo.split('/').at(-1)
      const byAuthor = {}
      for (const pr of d.prs) byAuthor[pr.author] = (byAuthor[pr.author] ?? 0) + 1
      for (const [author, count] of Object.entries(byAuthor).sort((a, b) => b[1] - a[1])) {
        rows.push({
          repo: repoName,
          author,
          count: { text: String(count), badge: true },
          link: {
            text: 'view',
            href: `https://github.com/${repo}/pulls?q=is:pr+is:open+author:${author}`,
            variant: 'primary',
          },
        })
      }
    }
    return {
      columns: [
        { key: 'repo', label: 'repo' },
        { key: 'author', label: 'author' },
        { key: 'count', label: 'prs', align: 'right', width: '60px' },
        { key: 'link', label: '', align: 'right', width: '50px' },
      ],
      rows,
    }
  }
}

export function githubPendingReview({ repos = [] } = {}) {
  return async () => {
    const qs = repos.map((r) => `repos[]=${encodeURIComponent(r)}`).join('&')
    const res = await get(`/api/github/pending-review?${qs}`)
    const items = Object.values(res.data).flatMap((d) => {
      if (d.error || !d.prs?.length) return []
      return d.prs.map((pr) => ({
        title: `#${pr.number} ${pr.title}`,
        subtitle: pr.author,
        badge: pr.approved_by_me ? 'approved' : null,
        badgeVariant: 'success',
        href: pr.html_url,
        meta: relTime(pr.created_at),
        status: pr.approved_by_me ? 'ok' : null,
      }))
    })
    return { items, emptyMessage: 'no pending reviews' }
  }
}
