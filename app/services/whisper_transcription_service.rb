class WhisperTranscriptionService
  Result = Struct.new(:success?, :text, :error, keyword_init: true)

  def initialize(audio_file)
    @audio_file = audio_file
    @client = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_KEY"))
  end

  def transcribe
    # Handle both ActionDispatch::Http::UploadedFile and File objects
    file_to_upload = @audio_file.respond_to?(:tempfile) ? @audio_file.tempfile : @audio_file

    response = @client.audio.transcribe(
      parameters: {
        model: "whisper-1",
        file: file_to_upload
      }
    )

    transcribed_text = response["text"]

    unless transcribed_text.present?
      error_msg = "Transcription returned empty text"
      Rails.logger.error "Whisper Transcription Error: #{error_msg}"
      return Result.new(success?: false, error: error_msg)
    end

    Result.new(success?: true, text: transcribed_text.strip)
  rescue StandardError => e
    Rails.logger.error "Whisper Transcription Error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n") if Rails.env.development?
    Result.new(success?: false, error: e.message)
  end
end
