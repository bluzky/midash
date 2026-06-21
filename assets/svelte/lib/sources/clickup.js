import { get } from '../api.js'
import { fmtDue } from '../fmt.js'

// mode: 'count' → stat-group shape (count per status)
// mode: 'list'  → list shape (all tasks as rows)
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

    // list mode — flat list of all tasks, badge shows status
    return {
      items: tasks.map((task) => {
        const due = fmtDue(task.due_date)
        return {
          title: task.name,
          badge: task.status?.status ?? null,
          badgeVariant: 'default',
          href: task.url,
          meta: due || null,
        }
      }),
    }
  }
}
