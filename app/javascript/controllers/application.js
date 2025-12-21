import { Application } from "@hotwired/stimulus"

import { Turbo } from "@hotwired/turbo-rails"
Turbo.setProgressBarDelay(0)  // show immediately

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

export { application }
