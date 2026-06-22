import { get } from '../api.js'
import { fmtCount, relTimeSec } from '../fmt.js'

export function sentryIssues({ org, project, environment, sort = 'freq' } = {}) {
  return async () => {
    const res = await get(
      `/api/sentry/issues?org=${org}&project=${project}&environment=${environment}&sort=${sort}`
    )
    return {
      columns: [
        { key: 'title', label: 'title' },
        { key: 'lastSeen', label: 'last seen', align: 'right', width: '80px' },
        { key: 'count', label: 'events', align: 'right', width: '80px' },
      ],
      rows: res.data.map((issue) => {
        const hot = parseInt(issue.count) > 1000
        return {
          title: { text: issue.title, href: issue.url, variant: hot ? 'error' : 'primary' },
          lastSeen: { text: relTimeSec(issue.lastSeen), variant: 'muted' },
          count: { text: fmtCount(issue.count), badge: true, variant: hot ? 'error' : 'default' },
        }
      }),
    }
  }
}
