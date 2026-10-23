import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "menu", "icon"]

  connect() {
    this.handleKeydown = (event) => {
      if (event.key === "Escape") this.close()
    }
    this.handleOutsideClick = (event) => {
      if (!this.element.contains(event.target)) this.close()
    }

    document.addEventListener("keydown", this.handleKeydown)
    document.addEventListener("click", this.handleOutsideClick)
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown)
    document.removeEventListener("click", this.handleOutsideClick)
    clearTimeout(this.hideMenuTimeout)
  }

  toggle() {
    if (this.menuTarget.hidden) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    clearTimeout(this.hideMenuTimeout)
    this.menuTarget.hidden = false
    this.menuTarget.classList.remove("opacity-100", "translate-y-0", "pointer-events-auto")
    this.menuTarget.classList.add("opacity-0", "-translate-y-2", "pointer-events-none")
    this.syncButtonState(true)

    requestAnimationFrame(() => {
      if (this.buttonTarget.getAttribute("aria-expanded") !== "true") return

      this.menuTarget.classList.remove("opacity-0", "-translate-y-2", "pointer-events-none")
      this.menuTarget.classList.add("opacity-100", "translate-y-0", "pointer-events-auto")
    })
  }

  close() {
    if (this.menuTarget.hidden) return

    clearTimeout(this.hideMenuTimeout)
    this.menuTarget.classList.remove("opacity-100", "translate-y-0", "pointer-events-auto")
    this.menuTarget.classList.add("opacity-0", "-translate-y-2", "pointer-events-none")
    this.syncButtonState(false)

    this.hideMenuTimeout = setTimeout(() => {
      if (this.buttonTarget.getAttribute("aria-expanded") === "false") {
        this.menuTarget.hidden = true
      }
    }, 200)
  }

  syncButtonState(isOpen) {
    this.buttonTarget.setAttribute("aria-expanded", String(isOpen))
    this.buttonTarget.setAttribute("aria-label", isOpen ? "Close menu" : "Open menu")
    this.iconTarget.classList.toggle("rotate-90", isOpen)
    this.iconTarget.classList.toggle("scale-90", isOpen)
    this.iconTarget.querySelector("path").setAttribute(
      "d",
      isOpen ? "M6 6l12 12M18 6 6 18" : "M4 6h16M4 12h16M4 18h16"
    )
  }
}
