import { get } from '../api.js'
import { fmtDue } from '../fmt.js'

const SKIP_STATUSES = new Set(['todo', 'completed'])
const STATUS_ORDER = ['verified', 'testing failed', 'in progress', 'in review', 'dev ready', 'ready for pro']

// mode: 'count' → stat-group shape (count per status)
// mode: 'list'  → flat list shape
// mode: 'tabs'  → tabs-list shape grouped by status (skips todo + completed)
export function clickupTasks({ mode = 'count' } = {}) {
  return async () => {
    const res = await get('/api/clickup/tasks')
    const tasks = res.data
    const statuses = res.statuses

    if (mode === 'count') {
      return {
        items: statuses.map((s) => ({
          value: String(tasks.filter((t) => (t.status?.status ?? '').toLowerCase() === s.key).length),
          label: s.label,
          color: s.color,
        })),
      }
    }

    if (mode === 'tabs') {
      const tabs = [...statuses]
        .filter((s) => !SKIP_STATUSES.has(s.key))
        .sort((a, b) => STATUS_ORDER.indexOf(a.key) - STATUS_ORDER.indexOf(b.key))
        .map((s) => {
          const items = tasks
            .filter((t) => (t.status?.status ?? '').toLowerCase() === s.key)
            .map((task) => ({
              title: task.name,
              href: task.url,
              meta: fmtDue(task.due_date) || null,
            }))
          return { key: s.key, label: s.label, count: items.length, items, emptyMessage: 'no tasks' }
        })
      return { tabs }
    }

    // list mode — flat list of all tasks, badge shows status
    return {
      items: tasks.map((task) => ({
        title: task.name,
        badge: task.status?.status ?? null,
        badgeVariant: 'default',
        href: task.url,
        meta: fmtDue(task.due_date) || null,
      })),
    }
  }
}
