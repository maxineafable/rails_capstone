import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  schedule() {
    window.clearTimeout(this.timeout)
    this.timeout = window.setTimeout(() => this.submit(), 350)
  }

  submit(event) {
    if (event?.key === "Enter") event.preventDefault()
    window.clearTimeout(this.timeout)
    this.element.form?.requestSubmit()
  }

  disconnect() {
    window.clearTimeout(this.timeout)
  }
}
