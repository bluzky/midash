export const THEMES = [
  { id: 'dark', label: 'Dark' },
  { id: 'light', label: 'Light' },
]

export function getStoredTheme() {
  return localStorage.getItem('theme') || 'dark'
}

export function applyTheme(theme) {
  const html = document.documentElement
  if (theme === 'dark') {
    html.classList.add('dark')
  } else {
    html.classList.remove('dark')
  }
  localStorage.setItem('theme', theme)
}

// Apply on load
applyTheme(getStoredTheme())
