import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["card"]

  connect() {
    this.activeIndex = this.cardTargets.findIndex((card) => card.dataset.position === "active")
    if (this.activeIndex < 0) this.activeIndex = 0
    this.handleResize = () => this.updateCards()
    this.handleScroll = () => this.updateActiveFromScroll()
    window.addEventListener("resize", this.handleResize)
    this.element.addEventListener("scroll", this.handleScroll, { passive: true })
    this.updateCards()
  }

  disconnect() {
    window.removeEventListener("resize", this.handleResize)
    this.element.removeEventListener("scroll", this.handleScroll)
  }

  select(event) {
    this.activeIndex = Number(event.currentTarget.dataset.index)
    this.updateCards()

    if (window.matchMedia("(max-width: 639px)").matches) {
      event.currentTarget.scrollIntoView({ behavior: "smooth", block: "nearest", inline: "center" })
    }
  }

  updateActiveFromScroll() {
    if (!window.matchMedia("(max-width: 639px)").matches) return

    const containerCenter = this.element.getBoundingClientRect().left + this.element.clientWidth / 2
    let closestIndex = this.activeIndex
    let closestDistance = Number.POSITIVE_INFINITY

    this.cardTargets.forEach((card, index) => {
      const rect = card.getBoundingClientRect()
      const distance = Math.abs(rect.left + rect.width / 2 - containerCenter)
      if (distance < closestDistance) {
        closestDistance = distance
        closestIndex = index
      }
    })

    if (closestIndex !== this.activeIndex) {
      this.activeIndex = closestIndex
      this.updateCards()
    }
  }

  updateCards() {
    const count = this.cardTargets.length
    const isMobile = window.matchMedia("(max-width: 639px)").matches

    if (isMobile) {
      const enteringMobileLayout = !this.mobileLayoutActive
      this.mobileLayoutActive = true
      const cardWidth = Math.min(this.element.clientWidth * 0.88, 570)
      this.element.style.height = "auto"
      this.element.style.display = "flex"
      this.element.style.alignItems = "stretch"
      this.element.style.gap = "12px"
      this.element.style.overflowX = "auto"
      this.element.style.overflowY = "hidden"
      this.element.style.padding = "0 12px 16px"
      this.element.style.scrollSnapType = "x mandatory"
      this.element.style.scrollSnapStop = "always"
      this.element.style.scrollPaddingInline = "12px"
      this.element.style.scrollbarWidth = "none"
      this.element.style.webkitOverflowScrolling = "touch"
      this.element.style.touchAction = "pan-x"

      this.cardTargets.forEach((card, index) => {
        const isActive = index === this.activeIndex
        card.style.position = "relative"
        card.style.left = "auto"
        card.style.top = "auto"
        card.style.width = `${cardWidth}px`
        card.style.minWidth = `${cardWidth}px`
        card.style.height = "auto"
        card.style.minHeight = "400px"
        card.style.flex = `0 0 ${cardWidth}px`
        card.style.transform = "none"
        card.style.opacity = "1"
        card.style.zIndex = "1"
        card.style.filter = "none"
        card.style.scrollSnapAlign = "center"
        card.style.cursor = isActive ? "default" : "pointer"
        card.setAttribute("aria-current", isActive ? "true" : "false")
        card.setAttribute("aria-label", `${card.dataset.title}${isActive ? ", selected" : ", click to select"}`)
        card.classList.toggle("ring-2", isActive)
        card.classList.toggle("ring-[#244fc4]", isActive)
      })

      if (enteringMobileLayout) {
        requestAnimationFrame(() => {
          this.cardTargets[this.activeIndex]?.scrollIntoView({ block: "nearest", inline: "center" })
        })
      }

      return
    }

    this.mobileLayoutActive = false
    this.element.removeAttribute("style")
    this.element.scrollLeft = 0

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
      card.style.position = "absolute"
      card.style.top = ""
      card.style.minWidth = ""
      card.style.height = ""
      card.style.minHeight = ""
      card.style.flex = ""
      card.style.scrollSnapAlign = ""
      card.style.cursor = ""
      card.setAttribute("aria-current", isActive ? "true" : "false")
      card.setAttribute("aria-label", `${card.dataset.title}${isActive ? ", selected" : ", click to select"}`)
      card.classList.toggle("cursor-pointer", !isActive)
      card.classList.remove("ring-2", "ring-[#244fc4]")
    })
  }
}
