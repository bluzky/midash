export const THEMES = [
  { id: 'system',          label: 'System',          color: null,      dark: null  },
  { id: 'red-graphite',    label: 'Red Graphite',    color: '#E04E46', dark: false },
  { id: 'solarized-slate', label: 'Solarized Slate', color: '#2A7B88', dark: false },
  { id: 'dark-graphite',   label: 'Dark Graphite',   color: '#F26C63', dark: true  },
  { id: 'nordic-forest',   label: 'Nordic Forest',   color: '#2C8A79', dark: false },
]

const SYSTEM_LIGHT = 'red-graphite'
const SYSTEM_DARK  = 'dark-graphite'

function resolveTheme(themeId) {
  if (themeId !== 'system') return THEMES.find((t) => t.id === themeId) ?? THEMES[1]
  const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches
  return THEMES.find((t) => t.id === (prefersDark ? SYSTEM_DARK : SYSTEM_LIGHT))
}

export function getStoredTheme() {
  return localStorage.getItem('theme') || 'system'
}

export function applyTheme(themeId) {
  const html = document.documentElement
  const theme = resolveTheme(themeId)
  html.setAttribute('data-theme', theme.id)
  if (theme.dark) {
    html.classList.add('dark')
  } else {
    html.classList.remove('dark')
  }
  localStorage.setItem('theme', themeId)
}

// Re-apply when OS preference changes (only matters while in system mode)
window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
  if (getStoredTheme() === 'system') applyTheme('system')
})

applyTheme(getStoredTheme())
