import { Controller } from "@hotwired/stimulus"

const WEEKDAYS = ["Lin", "Lun", "Mar", "Miy", "Huw", "Biy", "Sab"]

export default class extends Controller {
  static targets = [
    "trigger", "popup", "start", "end", "label", "message",
    "leftMonth", "rightMonth", "leftGrid", "rightGrid",
    "startDisplay", "endDisplay", "dayCount"
  ]

  connect() {
    const initialDate = this.startTarget.value || this.endTarget.value
    const today = initialDate ? this.parseDate(initialDate) : new Date()
    this.leftMonth = new Date(today.getFullYear(), today.getMonth(), 1)
    this.rightMonth = new Date(today.getFullYear(), today.getMonth() + 1, 1)
    this.updateLabel()
    this.renderCalendars()
  }

  toggle() {
    this.popupTarget.hidden = !this.popupTarget.hidden
    this.triggerTarget.setAttribute("aria-expanded", String(!this.popupTarget.hidden))
  }

  previousLeftMonth() {
    this.leftMonth = new Date(this.leftMonth.getFullYear(), this.leftMonth.getMonth() - 1, 1)
    this.renderCalendars()
  }

  nextLeftMonth() {
    this.leftMonth = new Date(this.leftMonth.getFullYear(), this.leftMonth.getMonth() + 1, 1)
    this.renderCalendars()
  }

  previousRightMonth() {
    this.rightMonth = new Date(this.rightMonth.getFullYear(), this.rightMonth.getMonth() - 1, 1)
    this.renderCalendars()
  }

  nextRightMonth() {
    this.rightMonth = new Date(this.rightMonth.getFullYear(), this.rightMonth.getMonth() + 1, 1)
    this.renderCalendars()
  }

  selectStartDate(event) {
    const selected = event.currentTarget.dataset.date
    if (!selected) return

    this.startTarget.value = selected
    if (this.endTarget.value && selected > this.endTarget.value) this.endTarget.value = ""
    this.messageTarget.textContent = this.endTarget.value ? "" : "Pumili ng petsa ng pagtatapos sa ikalawang kalendaryo."
    this.updateLabel()
    this.renderCalendars()
  }

  selectEndDate(event) {
    const selected = event.currentTarget.dataset.date
    if (!selected) return

    if (!this.startTarget.value) {
      this.messageTarget.textContent = "Pumili muna ng petsa ng pagsisimula sa unang kalendaryo."
      return
    }

    if (selected < this.startTarget.value) {
      this.messageTarget.textContent = "Pumili ng petsa ng pagtatapos na hindi mas maaga sa simula."
      return
    }

    this.endTarget.value = selected
    this.messageTarget.textContent = ""
    this.updateLabel()
    this.renderCalendars()
  }

  clear() {
    this.startTarget.value = ""
    this.endTarget.value = ""
    this.messageTarget.textContent = ""
    this.updateLabel()
    this.renderCalendars()
  }

  save() {
    const start = this.startTarget.value
    const end = this.endTarget.value

    if (Boolean(start) !== Boolean(end)) {
      this.messageTarget.textContent = start
        ? "Pumili ng petsa ng pagtatapos bago i-save."
        : "Pumili ng petsa ng pagsisimula bago i-save."
      return
    }

    if (start && end && start > end) {
      this.messageTarget.textContent = "Pumili ng wastong saklaw ng petsa."
      return
    }

    this.close()
    this.element.closest("form")?.requestSubmit()
  }

  closeOnOutside(event) {
    const clickedInside = this.element.contains(event.target) || event.composedPath().includes(this.element)
    if (!clickedInside) this.close()
  }

  close() {
    this.popupTarget.hidden = true
    this.triggerTarget.setAttribute("aria-expanded", "false")
  }

  updateLabel() {
    const start = this.formatDate(this.startTarget.value)
    const end = this.formatDate(this.endTarget.value)

    if (start && end) this.labelTarget.textContent = `${start} – ${end}`
    else if (start) this.labelTarget.textContent = `Mula ${start}`
    else if (end) this.labelTarget.textContent = `Hanggang ${end}`
    else this.labelTarget.textContent = "Pumili ng saklaw ng petsa"

    this.startDisplayTarget.textContent = start || "Simula"
    this.endDisplayTarget.textContent = end || "Pagtatapos"
    this.dayCountTarget.textContent = start && end ? this.daysBetween(start, end) : "—"
  }

  renderCalendars() {
    this.leftMonthTarget.textContent = this.formatMonth(this.leftMonth)
    this.rightMonthTarget.textContent = this.formatMonth(this.rightMonth)
    this.leftGridTarget.innerHTML = this.monthMarkup(this.leftMonth, "selectStartDate")
    this.rightGridTarget.innerHTML = this.monthMarkup(this.rightMonth, "selectEndDate")
  }

  monthMarkup(month, action) {
    const firstDay = new Date(month.getFullYear(), month.getMonth(), 1)
    const daysInMonth = new Date(month.getFullYear(), month.getMonth() + 1, 0).getDate()
    const start = this.startTarget.value
    const end = this.endTarget.value
    const cells = []

    for (let blank = 0; blank < firstDay.getDay(); blank += 1) cells.push('<span aria-hidden="true"></span>')

    for (let day = 1; day <= daysInMonth; day += 1) {
      const date = new Date(month.getFullYear(), month.getMonth(), day)
      const value = this.dateValue(date)
      const selected = action === "selectStartDate" ? value === start : value === end
      const inRange = start && end && value >= start && value <= end
      const selectionClasses = selected
        ? "rounded-full bg-blue-700 font-semibold text-white hover:bg-blue-800"
        : inRange
          ? "bg-sky-100 text-slate-800 hover:bg-sky-200"
          : "text-slate-700 hover:bg-blue-50"

      cells.push(`<button type="button" data-date="${value}" data-action="date-range#${action}" aria-pressed="${selected}" class="flex h-9 w-full items-center justify-center text-sm transition-colors ${selectionClasses}">${day}</button>`)
    }

    while (cells.length % 7 !== 0) cells.push('<span aria-hidden="true"></span>')

    return `${WEEKDAYS.map((weekday) => `<span class="py-2 text-center text-xs text-slate-500">${weekday}</span>`).join("")}${cells.join("")}`
  }

  formatMonth(date) {
    return new Intl.DateTimeFormat("fil-PH", { month: "long", year: "numeric" }).format(date)
  }

  formatDate(value) {
    if (!value) return ""
    return new Intl.DateTimeFormat("fil-PH", { month: "long", day: "numeric", year: "numeric" })
      .format(this.parseDate(value))
  }

  parseDate(value) {
    const [year, month, day] = value.split("-").map(Number)
    return new Date(year, month - 1, day)
  }

  dateValue(date) {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, "0")
    const day = String(date.getDate()).padStart(2, "0")
    return `${year}-${month}-${day}`
  }

  daysBetween(start, end) {
    const millisecondsPerDay = 24 * 60 * 60 * 1000
    return Math.round((this.parseDate(end) - this.parseDate(start)) / millisecondsPerDay) + 1
  }
}
