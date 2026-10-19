import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["card"]

  connect() {
    this.activeIndex = this.cardTargets.findIndex((card) => card.dataset.position === "active")
    if (this.activeIndex < 0) this.activeIndex = 0
    this.handleResize = () => this.updateCards()
    window.addEventListener("resize", this.handleResize)
    this.updateCards()
  }

  disconnect() {
    window.removeEventListener("resize", this.handleResize)
  }

  select(event) {
    this.activeIndex = Number(event.currentTarget.dataset.index)
    this.updateCards()
  }

  updateCards() {
    const count = this.cardTargets.length

    this.cardTargets.forEach((card, index) => {
      const relativePosition = (index - this.activeIndex + count) % count
      const isActive = relativePosition === 0
      const isRight = relativePosition === 1
      const offset = isActive ? 0 : (isRight ? 1 : -1)

      card.style.zIndex = isActive ? "20" : "10"
      card.style.opacity = isActive ? "1" : "0.78"
      card.style.width = "min(100%, 570px)"
      card.style.left = `${this.element.clientWidth / 2 + offset * this.element.clientWidth * 0.43}px`
      card.style.transform = `translate(-50%, -50%) perspective(900px) rotateY(${isActive ? 0 : offset * -8}deg) scale(${isActive ? 1 : 0.78})`
      card.style.filter = isActive ? "none" : "blur(0.3px)"
      card.setAttribute("aria-current", isActive ? "true" : "false")
      card.setAttribute("aria-label", `${card.dataset.title}${isActive ? ", selected" : ", click to select"}`)
      card.classList.toggle("cursor-pointer", !isActive)
    })
  }
}
