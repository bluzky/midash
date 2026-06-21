<script>
  let { data, config = {} } = $props()
  const { columns = [], rows = [] } = data ?? {}
  const {
    sortable = false,
    defaultSort = null,
    defaultSortDir = 'desc',
    limit = null,
    emptyMessage = 'no data',
  } = config

  let sortKey = $state(defaultSort)
  let sortDir = $state(defaultSortDir)

  function cellText(v) {
    if (v == null) return ''
    if (typeof v === 'object') return String(v.text ?? '')
    return String(v)
  }

  let displayRows = $derived.by(() => {
    let r = [...rows]
    if (sortKey) {
      r.sort((a, b) => {
        const cmp = cellText(a[sortKey]).localeCompare(cellText(b[sortKey]), undefined, { numeric: true })
        return sortDir === 'asc' ? cmp : -cmp
      })
    }
    return limit ? r.slice(0, limit) : r
  })

  function toggleSort(key) {
    if (!sortable) return
    if (sortKey === key) sortDir = sortDir === 'asc' ? 'desc' : 'asc'
    else { sortKey = key; sortDir = 'desc' }
  }

  const ALIGN = { left: 'text-left', right: 'text-right', center: 'text-center' }

  const VARIANT = {
    default: '',
    muted: 'text-muted-foreground',
    success: 'text-success',
    warning: 'text-warning',
    error: 'text-destructive',
    primary: 'text-primary',
  }
</script>

{#if !rows.length}
  <div class="text-muted-foreground text-sm">{emptyMessage}</div>
{:else}
  <table class="w-full table-fixed text-sm">
    <thead>
      <tr class="border-b border-border text-muted-foreground text-xs uppercase">
        {#each columns as col}
          <th
            class="py-1 px-0 font-normal {ALIGN[col.align ?? 'left']} {sortable ? 'cursor-pointer select-none hover:text-foreground' : ''}"
            style={col.width ? `width: ${col.width}` : ''}
            onclick={() => toggleSort(col.key)}
          >
            {col.label}{#if sortable && sortKey === col.key}{sortDir === 'asc' ? ' ↑' : ' ↓'}{/if}
          </th>
        {/each}
      </tr>
    </thead>
    <tbody class="divide-y divide-border">
      {#each displayRows as row}
        <tr class="hover:bg-secondary transition-colors">
          {#each columns as col}
            {@const cell = row[col.key]}
            {@const isObj = cell != null && typeof cell === 'object'}
            {@const text = cellText(cell)}
            {@const variant = isObj ? (cell.variant ?? 'default') : 'default'}
            <td
              class="py-1.5 px-0 min-w-0 {ALIGN[col.align ?? 'left']} {VARIANT[variant]}"
              style={col.width ? `width: ${col.width}` : ''}
            >
              {#if isObj && cell.href}
                <a href={cell.href} target="_blank" class="underline truncate block">{text}</a>
              {:else if isObj && cell.badge}
                <span class="bg-secondary/50 px-2 py-0.5 rounded-full text-xs font-mono tabular-nums inline-block">{text}</span>
              {:else}
                <span class="truncate block">{text}</span>
              {/if}
            </td>
          {/each}
        </tr>
      {/each}
    </tbody>
  </table>
{/if}
