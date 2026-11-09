// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

document.addEventListener("change", (event) => {
  const input = event.target
  if (!(input instanceof HTMLInputElement) || !input.matches("[data-photo-picker]")) return

  const filename = document.getElementById(input.dataset.filenameTarget)
  const preview = document.getElementById(input.dataset.previewTarget)
  const previewContainer = preview?.parentElement
  if (input.files?.length) {
    const otherInput = document.getElementById(input.dataset.otherPicker)
    if (otherInput) otherInput.value = ""
    const file = input.files[0]
    const uploadInput = document.getElementById(input.dataset.uploadTarget)
    if (uploadInput && input !== uploadInput) {
      const transfer = new DataTransfer()
      transfer.items.add(file)
      uploadInput.files = transfer.files
      input.value = ""
      uploadInput.dispatchEvent(new Event("change", { bubbles: true }))
    }
    if (filename) filename.textContent = file.name
    if (preview && file.type.startsWith("image/")) {
      if (preview.dataset.objectUrl) URL.revokeObjectURL(preview.dataset.objectUrl)
      preview.dataset.objectUrl = URL.createObjectURL(file)
      preview.src = preview.dataset.objectUrl
      previewContainer?.classList.remove("hidden")
    }
    if (input.dataset.cameraGroup) closePhotoCamera(input.dataset.cameraGroup)
    if (input.id === "valid-id-gallery") checkIdImageQuality(file)
    if (input.id === "concern-evidence-gallery") checkConcernEvidenceQuality(file)
  } else {
    if (filename) filename.textContent = "Wala pang napipiling larawan"
    if (preview) {
      if (preview.dataset.objectUrl) URL.revokeObjectURL(preview.dataset.objectUrl)
      delete preview.dataset.objectUrl
      preview.removeAttribute("src")
      previewContainer?.classList.add("hidden")
    }
    if (input.id === "valid-id-gallery") setIdImageQualityState("missing")
    if (input.id === "concern-evidence-gallery") setConcernEvidenceQualityState("missing")
  }
})

const photoCameraConfigs = {
  "valid-id": { input: "valid-id-camera", panel: "valid-id-camera-panel", video: "valid-id-camera-video", message: "valid-id-camera-message", captured: "valid-id-camera-captured" },
  "concern-evidence": { input: "concern-evidence-camera", panel: "concern-evidence-camera-panel", video: "concern-evidence-camera-video", message: "concern-evidence-camera-message", captured: "concern-evidence-camera-captured" }
}
const photoCameraStates = new Map()
let idImageCheckToken = 0
let concernEvidenceCheckToken = 0

function setIdImageQualityState(state) {
  const form = document.getElementById("document-request-form")
  const submit = document.getElementById("document-request-review")
  const warning = document.getElementById("valid-id-blur-warning")
  const checking = document.getElementById("valid-id-quality-checking")
  if (!form) return

  form.dataset.idQualityState = state
  // Keep the review button clickable for an invalid image so the submit
  // handler can guide the user back to the warning. While checking, prevent
  // duplicate submissions until the quality check finishes.
  if (submit) submit.disabled = state === "checking"
  warning?.classList.toggle("hidden", state !== "invalid")
  checking?.classList.toggle("hidden", state !== "checking")

}

async function imageSharpnessScore(file) {
  if (!file.type.startsWith("image/")) throw new Error("Unsupported image")

  let bitmap
  let objectUrl
  try {
    if (window.createImageBitmap) {
      bitmap = await createImageBitmap(file)
    } else {
      const image = new Image()
      objectUrl = URL.createObjectURL(file)
      image.src = objectUrl
      await new Promise((resolve, reject) => {
        image.onload = resolve
        image.onerror = reject
      })
      bitmap = image
    }

    const maxSide = 640
    const scale = Math.min(1, maxSide / Math.max(bitmap.width, bitmap.height))
    const width = Math.max(3, Math.round(bitmap.width * scale))
    const height = Math.max(3, Math.round(bitmap.height * scale))
    const canvas = document.createElement("canvas")
    canvas.width = width
    canvas.height = height
    const context = canvas.getContext("2d", { willReadFrequently: true })
    if (!context) throw new Error("Canvas unavailable")
    context.imageSmoothingQuality = "high"
    context.drawImage(bitmap, 0, 0, width, height)

    const { data } = context.getImageData(0, 0, width, height)
    const gray = new Float32Array(width * height)
    for (let index = 0, pixel = 0; index < data.length; index += 4, pixel += 1) {
      gray[pixel] = 0.299 * data[index] + 0.587 * data[index + 1] + 0.114 * data[index + 2]
    }

    let sum = 0
    let sumSquares = 0
    let samples = 0
    for (let y = 1; y < height - 1; y += 1) {
      for (let x = 1; x < width - 1; x += 1) {
        const index = y * width + x
        const laplacian = 4 * gray[index] - gray[index - 1] - gray[index + 1] - gray[index - width] - gray[index + width]
        sum += laplacian
        sumSquares += laplacian * laplacian
        samples += 1
      }
    }

    const mean = sum / samples
    return sumSquares / samples - mean * mean
  } finally {
    bitmap?.close?.()
    if (objectUrl) URL.revokeObjectURL(objectUrl)
  }
}

async function checkIdImageQuality(file) {
  const input = document.getElementById("valid-id-gallery")
  const token = ++idImageCheckToken
  setIdImageQualityState("checking")

  try {
    const score = await imageSharpnessScore(file)
    if (token !== idImageCheckToken || input?.files?.[0] !== file) return
    setIdImageQualityState(score >= 120 ? "valid" : "invalid")
  } catch (_error) {
    if (token === idImageCheckToken) setIdImageQualityState("invalid")
  }
}

function setConcernEvidenceQualityState(state) {
  const input = document.getElementById("concern-evidence-gallery")
  const form = input?.form
  const warning = document.getElementById("concern-evidence-blur-warning")
  const checking = document.getElementById("concern-evidence-quality-checking")
  if (!form) return

  form.dataset.concernEvidenceQualityState = state
  warning?.classList.toggle("hidden", state !== "invalid")
  checking?.classList.toggle("hidden", state !== "checking")
}

async function checkConcernEvidenceQuality(file) {
  const input = document.getElementById("concern-evidence-gallery")
  const token = ++concernEvidenceCheckToken
  setConcernEvidenceQualityState("checking")

  try {
    const score = await imageSharpnessScore(file)
    if (token !== concernEvidenceCheckToken || input?.files?.[0] !== file) return
    setConcernEvidenceQualityState(score >= 120 ? "valid" : "invalid")
  } catch (_error) {
    if (token === concernEvidenceCheckToken) setConcernEvidenceQualityState("invalid")
  }
}

function photoCameraButton(group, action) {
  return document.querySelector(`[data-camera-group="${group}"][data-camera-action="${action}"]`)
}

function photoCameraState(group) {
  if (!photoCameraStates.has(group)) photoCameraStates.set(group, { stream: null, blob: null, url: null })
  return photoCameraStates.get(group)
}

function stopPhotoCamera(group) {
  const config = photoCameraConfigs[group]
  const state = photoCameraState(group)
  state.stream?.getTracks().forEach((track) => track.stop())
  state.stream = null
  const video = config && document.getElementById(config.video)
  if (video) video.srcObject = null
}

function closePhotoCamera(group) {
  const config = photoCameraConfigs[group]
  if (!config) return
  const state = photoCameraState(group)
  stopPhotoCamera(group)
  if (state.url) URL.revokeObjectURL(state.url)
  state.url = null
  state.blob = null
  document.getElementById(config.panel)?.classList.add("hidden")
}

async function openPhotoCamera(group) {
  const config = photoCameraConfigs[group]
  if (!config) return
  const panel = document.getElementById(config.panel)
  const video = document.getElementById(config.video)
  const message = document.getElementById(config.message)
  const fallback = photoCameraButton(group, "fallback")
  const captured = document.getElementById(config.captured)
  if (!panel || !video || !message) return

  const state = photoCameraState(group)
  panel.classList.remove("hidden")
  captured?.classList.add("hidden")
  video.classList.remove("hidden")
  photoCameraButton(group, "capture")?.classList.remove("hidden")
  photoCameraButton(group, "retake")?.classList.add("hidden")
  photoCameraButton(group, "use")?.classList.add("hidden")
  fallback?.classList.add("hidden")
  message.textContent = "Binubuksan ang camera…"

  if (!navigator.mediaDevices?.getUserMedia) {
    message.textContent = "Hindi direktang mabuksan ng browser na ito ang camera. Pumili ng larawan gamit ang device."
    fallback?.classList.remove("hidden")
    return
  }

  try {
    stopPhotoCamera(group)
    state.stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: { ideal: "environment" } }, audio: false })
    video.srcObject = state.stream
    await video.play()
    message.textContent = group === "valid-id" ? "Iharap ang ID sa camera." : "Iharap ang larawan ng suliranin sa camera."
  } catch (error) {
    stopPhotoCamera(group)
    message.textContent = "Hindi mabuksan ang camera. Payagan ang paggamit ng camera o pumili ng larawan sa device."
    fallback?.classList.remove("hidden")
  }
}

function capturePhoto(group) {
  const config = photoCameraConfigs[group]
  if (!config) return
  const video = document.getElementById(config.video)
  const captured = document.getElementById(config.captured)
  const message = document.getElementById(config.message)
  if (!video || !captured || !video.videoWidth) return

  const canvas = document.createElement("canvas")
  canvas.width = video.videoWidth
  canvas.height = video.videoHeight
  canvas.getContext("2d")?.drawImage(video, 0, 0, canvas.width, canvas.height)
  canvas.toBlob((blob) => {
    if (!blob) {
      if (message) message.textContent = "Hindi na-save ang larawan. Subukang kumuha muli."
      return
    }
    const state = photoCameraState(group)
    if (state.url) URL.revokeObjectURL(state.url)
    state.blob = blob
    state.url = URL.createObjectURL(blob)
    captured.src = state.url
    captured.classList.remove("hidden")
    video.classList.add("hidden")
    photoCameraButton(group, "capture")?.classList.add("hidden")
    photoCameraButton(group, "retake")?.classList.remove("hidden")
    photoCameraButton(group, "use")?.classList.remove("hidden")
    if (message) message.textContent = "Suriin ang larawan. Maaari itong gamitin o kumuha muli."
  }, "image/jpeg", 0.92)
}

function retakePhoto(group) {
  const config = photoCameraConfigs[group]
  if (!config) return
  const state = photoCameraState(group)
  if (state.url) URL.revokeObjectURL(state.url)
  state.url = null
  state.blob = null
  document.getElementById(config.captured)?.classList.add("hidden")
  document.getElementById(config.video)?.classList.remove("hidden")
  photoCameraButton(group, "capture")?.classList.remove("hidden")
  photoCameraButton(group, "retake")?.classList.add("hidden")
  photoCameraButton(group, "use")?.classList.add("hidden")
  const message = document.getElementById(config.message)
  if (message) message.textContent = group === "valid-id" ? "Iharap ang ID sa camera." : "Iharap ang larawan ng suliranin sa camera."
}

function usePhoto(group) {
  const config = photoCameraConfigs[group]
  const state = photoCameraState(group)
  if (!config || !state.blob) return
  const input = document.getElementById(config.input)
  if (!input) return
  const prefix = group === "valid-id" ? "valid-id" : "concern-evidence"
  const file = new File([state.blob], `${prefix}-${Date.now()}.jpg`, { type: "image/jpeg" })
  const transfer = new DataTransfer()
  transfer.items.add(file)
  input.files = transfer.files
  input.dispatchEvent(new Event("change", { bubbles: true }))
  closePhotoCamera(group)
}

document.addEventListener("click", (event) => {
  const button = event.target.closest("button")
  if (!button) return
  if (button.dataset.cameraOpen) openPhotoCamera(button.dataset.cameraOpen)
  if (button.dataset.idQualityRetry) {
    openPhotoCamera("valid-id")
    return
  }
  const group = button.dataset.cameraGroup
  if (!group) return
  if (button.dataset.cameraAction === "capture") capturePhoto(group)
  if (button.dataset.cameraAction === "retake") retakePhoto(group)
  if (button.dataset.cameraAction === "use") usePhoto(group)
  if (button.dataset.cameraAction === "cancel") closePhotoCamera(group)
  if (button.dataset.cameraAction === "fallback") document.getElementById(photoCameraConfigs[group]?.input)?.click()
})

document.addEventListener("turbo:before-cache", () => Object.keys(photoCameraConfigs).forEach(closePhotoCamera))

function requiredFieldIsValid(field) {
  if (field.type === "radio" && field.form?.querySelector("[data-category-group]")) {
    return Boolean(field.form.querySelector("[data-category-group] input[type='radio']:checked"))
  }
  return field.checkValidity()
}

function clearRequiredFeedback(field) {
  const form = field.form
  if (!form) return
  const categoryGroup = field.type === "radio" ? form.querySelector("[data-category-group]") : null
  if (categoryGroup) {
    categoryGroup.classList.remove("rounded-lg", "ring-2", "ring-red-400", "ring-offset-2")
    form.querySelector("[data-category-error]")?.classList.add("hidden")
    form.querySelectorAll("[data-category-group] input[type='radio']").forEach((radio) => radio.removeAttribute("aria-invalid"))
  } else {
    const upload = field.closest("[data-required-upload]")
    ;(upload || field).classList.remove("ring-2", "ring-red-400", "ring-offset-2", "bg-red-50")
    field.removeAttribute("aria-invalid")
  }

  const requiredFields = Array.from(form.querySelectorAll("input:required, select:required, textarea:required"))
  if (requiredFields.every(requiredFieldIsValid)) form.querySelector("[data-required-summary]")?.classList.add("hidden")
}

document.addEventListener("invalid", (event) => {
  const field = event.target
  const form = field.form
  if (!form?.dataset.requiredValidation) return

  form.querySelector("[data-required-summary]")?.classList.remove("hidden")
  if (field.type === "radio" && form.querySelector("[data-category-group]")) {
    form.querySelector("[data-category-group]")?.classList.add("rounded-lg", "ring-2", "ring-red-400", "ring-offset-2")
    form.querySelector("[data-category-error]")?.classList.remove("hidden")
    form.querySelectorAll("[data-category-group] input[type='radio']").forEach((radio) => radio.setAttribute("aria-invalid", "true"))
  } else {
    const upload = field.closest("[data-required-upload]")
    ;(upload || field).classList.add("ring-2", "ring-red-400", "ring-offset-2", "bg-red-50")
    field.setAttribute("aria-invalid", "true")
  }
}, true)

document.addEventListener("input", (event) => {
  const field = event.target
  if (field.form?.dataset.requiredValidation && field.required && requiredFieldIsValid(field)) clearRequiredFeedback(field)
})

document.addEventListener("change", (event) => {
  const field = event.target
  if (field.form?.dataset.requiredValidation && field.required && requiredFieldIsValid(field)) clearRequiredFeedback(field)
})

document.addEventListener("submit", (event) => {
  const form = event.target
  if (form.id === "document-request-form" && ["checking", "invalid"].includes(form.dataset.idQualityState)) {
    event.preventDefault()
    document.getElementById(form.dataset.idQualityState === "invalid" ? "valid-id-blur-warning" : "valid-id-quality-checking")?.scrollIntoView({ behavior: "smooth", block: "center" })
  }

  const evidenceInput = form.querySelector?.("#concern-evidence-gallery")
  if (evidenceInput?.files?.length && ["checking", "invalid"].includes(form.dataset.concernEvidenceQualityState)) {
    event.preventDefault()
    document.getElementById(form.dataset.concernEvidenceQualityState === "invalid" ? "concern-evidence-blur-warning" : "concern-evidence-quality-checking")?.scrollIntoView({ behavior: "smooth", block: "center" })
  }
}, true)
