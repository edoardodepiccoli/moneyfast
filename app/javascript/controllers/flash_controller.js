import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="flash"
export default class extends Controller {
  static targets = ["message"]

  connect() {
    this.messageTargets.forEach(message => {
      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          message.style.transform = "translateY(0)"
        })
      })

      setTimeout(() => {
        this.dismiss(message)
      }, 3000)
    })
  }

  dismiss(message) {
    message.style.transform = "translateY(100%)"

    setTimeout(() => {
      message.remove()
    }, 300)
  }
}
