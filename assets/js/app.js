// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

const THEMES = ["dark", "light", "ocean", "forest", "sunset", "midnight", "nord", "latte", "paper", "rose", "mint"]

function getStoredTheme() {
  return localStorage.getItem("theme") || "dark"
}

function applyTheme(theme) {
  const html = document.documentElement
  html.classList.remove("dark")
  html.removeAttribute("data-theme")

  if (theme === "dark") {
    html.classList.add("dark")
  } else if (theme !== "light") {
    html.setAttribute("data-theme", theme)
  }

  localStorage.setItem("theme", theme)

  // update any label elements
  document.querySelectorAll("#theme-label").forEach(el => {
    el.textContent = theme
  })
}

;(function() {
  applyTheme(getStoredTheme())
})()

window.setTheme = (theme) => {
  if (THEMES.includes(theme)) applyTheme(theme)
}

window.addEventListener("phx:set-theme", (e) => {
  const theme = e.detail?.theme
  if (theme && THEMES.includes(theme)) {
    applyTheme(theme)
  }
})

// Close theme menu when clicking outside
document.addEventListener("click", (e) => {
  const switcher = document.getElementById("theme-switcher")
  const menu = document.getElementById("theme-menu")
  if (menu && switcher && !switcher.contains(e.target)) {
    menu.classList.add("hidden")
  }
})

window.getTheme = () => getStoredTheme()
window.getThemes = () => THEMES

// LiveView hook: syncs the label text to the current theme on mount
const ThemeSwitcher = {
  mounted() {
    const label = this.el.querySelector("#theme-label")
    if (label) label.textContent = getStoredTheme()
  }
}

let hooks = { ThemeSwitcher }

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

