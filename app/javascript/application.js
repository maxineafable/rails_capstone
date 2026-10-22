// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

document.addEventListener("change", (event) => {
  const input = event.target
  if (!(input instanceof HTMLInputElement) || !input.matches("[data-photo-picker]")) return

  const filename = document.getElementById(input.dataset.filenameTarget)
  if (input.files?.length) {
    const otherInput = document.getElementById(input.dataset.otherPicker)
    if (otherInput) otherInput.value = ""
    if (filename) filename.textContent = input.files[0].name
  }
})
