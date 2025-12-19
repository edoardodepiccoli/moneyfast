import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="flash"
export default class extends Controller {
  static targets = ["message"]

  connect() {
    this.messageTargets.forEach(message => {
      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          message.classList.remove("translate-y-full")
        })
      })

      setTimeout(() => {
        this.dismiss(message)
      }, 1500)
    })
  }

  dismiss(message) {
    message.classList.add("translate-y-full")

    setTimeout(() => {
      message.remove()
    }, 100)
  }
}
