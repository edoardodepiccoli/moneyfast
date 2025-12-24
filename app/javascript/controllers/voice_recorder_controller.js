import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [
        "form",
        "visualizer",
        "canvas",
        "micButton",
        "inputField",
        "timer",
        "stopButton",
        "errorMessage"
    ]

    static values = {
        transcribeUrl: String
    }

    connect() {
        // Hide microphone button if MediaRecorder API is not supported
        if (!navigator.mediaDevices || !window.MediaRecorder) {
            if (this.hasMicButtonTarget) {
                this.micButtonTarget.classList.add("hidden")
            }
            return
        }

        this.state = "idle" // idle, recording, sending
        this.mediaRecorder = null
        this.audioChunks = []
        this.audioBlob = null
        this.audioContext = null
        this.analyser = null
        this.animationFrame = null
        this.startTime = null
        this.timerInterval = null
        this.stream = null
    }

    disconnect() {
        this.stopRecording()
        this.cleanup()
    }

    async startRecording() {
        try {
            // Request microphone access
            this.stream = await navigator.mediaDevices.getUserMedia({ audio: true })

            // Initialize audio context for visualization
            this.audioContext = new (window.AudioContext || window.webkitAudioContext)()
            const source = this.audioContext.createMediaStreamSource(this.stream)
            this.analyser = this.audioContext.createAnalyser()
            this.analyser.fftSize = 256
            source.connect(this.analyser)

            // Initialize MediaRecorder
            this.mediaRecorder = new MediaRecorder(this.stream, {
                mimeType: MediaRecorder.isTypeSupported("audio/webm") ? "audio/webm" : "audio/ogg"
            })
            this.audioChunks = []

            this.mediaRecorder.ondataavailable = (event) => {
                if (event.data.size > 0) {
                    this.audioChunks.push(event.data)
                }
            }

            this.mediaRecorder.onstop = () => {
                this.audioBlob = new Blob(this.audioChunks, { type: this.mediaRecorder.mimeType })
                // Automatically send the recording
                this.sendRecording()
            }

            // Start recording
            this.mediaRecorder.start()
            this.state = "recording"
            this.startTime = Date.now()
            this.showVisualizer()
            this.startTimer()
            this.startWaveform()
            this.updateUIState()

        } catch (error) {
            console.error("Error accessing microphone:", error)
            this.showError("Microphone access denied. Please allow microphone access to record audio.")
        }
    }

    stopRecording() {
        if (this.mediaRecorder && this.state === "recording") {
            this.mediaRecorder.stop()
            // Note: cleanup happens after sending completes
        }
    }

    async sendRecording() {
        if (!this.audioBlob) {
            this.showError("No recording available to send.")
            this.resetForm()
            return
        }

        this.state = "sending"
        this.cleanupStream()
        this.stopTimer()
        this.stopWaveform()
        this.updateUIState()

        const formData = new FormData()
        formData.append("audio_file", this.audioBlob, "recording.webm")

        try {
            const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
            const headers = {}
            if (csrfToken) {
                headers["X-CSRF-Token"] = csrfToken
            }

            const response = await fetch(this.transcribeUrlValue, {
                method: "POST",
                body: formData,
                headers: headers
            })

            const data = await response.json()

            if (data.success) {
                // Prepend the transaction HTML to the transactions list for immediate feedback
                // The Turbo Stream broadcast will update it later when processing completes
                if (data.transaction_html) {
                    const transactionsList = document.getElementById("transactions_list")
                    if (transactionsList) {
                        // Create a temporary container to parse the HTML and extract the turbo-frame
                        const tempDiv = document.createElement("div")
                        tempDiv.innerHTML = data.transaction_html.trim()
                        const transactionElement = tempDiv.firstElementChild

                        if (transactionElement) {
                            // Check if element with same ID already exists (Turbo will handle duplicates, but avoid inserting twice)
                            const existingElement = transactionElement.id ? document.getElementById(transactionElement.id) : null
                            if (!existingElement) {
                                // Insert at the beginning of the list
                                transactionsList.insertBefore(transactionElement, transactionsList.firstChild)
                            }
                        }
                    }
                }

                // Reset form
                this.resetForm()
            } else {
                this.showError(data.error || "Failed to transcribe audio. Please try again.")
                this.resetForm()
            }
        } catch (error) {
            console.error("Error sending recording:", error)
            this.showError("Network error. Please check your connection and try again.")
            this.resetForm()
        }
    }

    showVisualizer() {
        if (this.hasFormTarget) this.formTarget.classList.add("hidden")
        if (this.hasVisualizerTarget) this.visualizerTarget.classList.remove("hidden")
        if (this.hasMicButtonTarget) this.micButtonTarget.classList.add("hidden")
    }

    resetForm() {
        this.state = "idle"
        this.audioBlob = null
        this.audioChunks = []

        if (this.hasFormTarget) this.formTarget.classList.remove("hidden")
        if (this.hasVisualizerTarget) this.visualizerTarget.classList.add("hidden")
        if (this.hasMicButtonTarget) this.micButtonTarget.classList.remove("hidden")

        this.cleanup()
        this.updateUIState()
    }

    updateUIState() {
        const isIdle = this.state === "idle"
        const isRecording = this.state === "recording"
        const isSending = this.state === "sending"

        if (this.hasStopButtonTarget) {
            this.stopButtonTarget.disabled = !isRecording || isSending
            this.stopButtonTarget.classList.toggle("hidden", !isRecording)
        }

        if (this.hasVisualizerTarget && isSending) {
            // Show sending message in visualizer
            const timerElement = this.hasTimerTarget ? this.timerTarget : null
            if (timerElement) {
                timerElement.textContent = "Sending..."
            }
        }
    }

    startTimer() {
        this.timerInterval = setInterval(() => {
            if (this.startTime) {
                const elapsed = Math.floor((Date.now() - this.startTime) / 1000)
                const minutes = Math.floor(elapsed / 60)
                const seconds = elapsed % 60
                const timeString = `${minutes}:${seconds.toString().padStart(2, "0")}`
                if (this.hasTimerTarget) {
                    this.timerTarget.textContent = timeString
                }
            }
        }, 1000)
    }

    stopTimer() {
        if (this.timerInterval) {
            clearInterval(this.timerInterval)
            this.timerInterval = null
        }
    }

    startWaveform() {
        if (!this.hasCanvasTarget || !this.analyser) return

        const canvas = this.canvasTarget
        const ctx = canvas.getContext("2d")
        const bufferLength = this.analyser.frequencyBinCount
        const dataArray = new Uint8Array(bufferLength)

        const draw = () => {
            if (this.state !== "recording") return

            this.animationFrame = requestAnimationFrame(draw)

            this.analyser.getByteFrequencyData(dataArray)

            ctx.fillStyle = "rgb(255, 255, 255)"
            ctx.fillRect(0, 0, canvas.width, canvas.height)

            const barWidth = (canvas.width / bufferLength) * 2.5
            let barHeight
            let x = 0

            for (let i = 0; i < bufferLength; i++) {
                barHeight = (dataArray[i] / 255) * canvas.height

                const r = barHeight + 25 * (i / bufferLength)
                const g = 50 * (i / bufferLength)
                const b = 200

                ctx.fillStyle = `rgb(${r},${g},${b})`
                ctx.fillRect(x, canvas.height - barHeight, barWidth, barHeight)

                x += barWidth + 1
            }
        }

        draw()
    }

    stopWaveform() {
        if (this.animationFrame) {
            cancelAnimationFrame(this.animationFrame)
            this.animationFrame = null
        }
        if (this.hasCanvasTarget) {
            const ctx = this.canvasTarget.getContext("2d")
            ctx.clearRect(0, 0, this.canvasTarget.width, this.canvasTarget.height)
        }
    }

    cleanupStream() {
        if (this.stream) {
            this.stream.getTracks().forEach(track => track.stop())
            this.stream = null
        }
        if (this.audioContext) {
            this.audioContext.close()
            this.audioContext = null
        }
        this.analyser = null
    }

    cleanup() {
        this.cleanupStream()
        this.stopTimer()
        this.stopWaveform()
        this.startTime = null
    }

    showError(message) {
        if (this.hasErrorMessageTarget) {
            this.errorMessageTarget.textContent = message
            this.errorMessageTarget.classList.remove("hidden")
            setTimeout(() => {
                if (this.hasErrorMessageTarget) {
                    this.errorMessageTarget.classList.add("hidden")
                }
            }, 5000)
        }
    }
}

