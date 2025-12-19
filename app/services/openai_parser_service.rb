class OpenaiParserService
  def initialize(raw_input)
    @raw_input = raw_input
    @client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"] || ENV.fetch("OPENAI_API_KEY"))
  end

  def parse
    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: system_prompt },
          { role: "user", content: @raw_input }
        ],
        response_format: { type: "json_object" },
        temperature: 0
      }
    )

    JSON.parse(response.dig("choices", 0, "message", "content"))
  rescue StandardError => e
    Rails.logger.error "OpenAI Parsing Error: #{e.message}"
    nil
  end

  private

  def system_prompt
    <<~TEXT
      You are a financial assistant.

      Parse the user's input into JSON with these keys:
      - "amount": (float, positive or negative, default to negative if not specified that it's a positive amount)
      - "description": (string, meaningful description for the transaction specified in the user message below written in the user's language, max 255 characters, properly capitalized)
      - "date": (string YYYY-MM-DD). If no date is provided, use today's date. Today is #{Date.today}.
    TEXT
  end
end
