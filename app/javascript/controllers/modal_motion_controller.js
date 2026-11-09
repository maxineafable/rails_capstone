import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    requestAnimationFrame(() => this.element.classList.add("is-visible"))
  }

  close(event) {
    event?.preventDefault()
    if (this.element.classList.contains("is-leaving")) return

    this.element.classList.add("is-leaving")
    const closeDelay = window.matchMedia("(prefers-reduced-motion: reduce)").matches ? 1 : 320
    window.setTimeout(() => this.element.remove(), closeDelay)
  }

  backdrop(event) {
    if (event.target === this.element) this.close(event)
  }
}
