import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dot", "count", "list"]
  static values = { readUrl: String }

  markRead() {
    if (!this.element.open || !this.hasDotTarget) return

    this.dotTarget.remove()
    this.sendRequest(this.readUrlValue, "POST").catch(() => {})
  }

  async remove(event) {
    event.preventDefault()
    const response = await this.sendRequest(event.currentTarget.dataset.url, "DELETE")
    if (!response?.ok) return

    event.currentTarget.closest("[data-notification-item]")?.remove()
    this.updateInbox(await response.json())
  }

  async clearAll(event) {
    event.preventDefault()
    const response = await this.sendRequest(event.currentTarget.dataset.url, "DELETE")
    if (!response?.ok) return

    this.listTarget.replaceChildren()
    this.updateInbox(await response.json())
  }

  async sendRequest(url, method) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    return fetch(url, {
      method,
      credentials: "same-origin",
      headers: { "Accept": "application/json", "X-CSRF-Token": csrfToken }
    })
  }

  updateInbox(counts) {
    if (this.hasCountTarget) this.countTarget.textContent = counts.remaining_count

    if (counts.unread_count > 0) {
      if (!this.hasDotTarget) {
        const dot = document.createElement("span")
        dot.dataset.notificationMenuTarget = "dot"
        dot.className = "absolute right-1 top-1 h-2 w-2 rounded-full bg-red-500 ring-2 ring-white"
        dot.setAttribute("aria-label", "May hindi pa nababasang notification")
        this.element.querySelector("summary")?.append(dot)
      }
    } else if (this.hasDotTarget) {
      this.dotTarget.remove()
    }

    if (counts.remaining_count === 0) {
      const empty = document.createElement("p")
      empty.dataset.notificationEmpty = ""
      empty.className = "px-4 py-8 text-center text-xs text-slate-500"
      empty.textContent = "Wala pang mga update."
      this.listTarget.replaceChildren(empty)
      this.element.querySelector('[data-action~="click->notification-menu#clearAll"]')?.remove()
    }
  }

  close() {
    this.element.open = false
  }
}
