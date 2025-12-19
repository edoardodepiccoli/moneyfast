class OpenaiParserService
  def initialize(raw_input)
    @raw_input = raw_input
    @client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"] || ENV.fetch("OPENAI_API_KEY"))
  end

  def parse
    response = @client.chat(
      parameters: {
        model: "gpt-4o",
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
      parse the user's input into JSON with these keys:

      - "amount"
      - "description"
      - "date": (string YYYY-MM-DD). If no date is provided, use today's date. Today is #{Date.today}.

      the amount should be a float. it should be negative if the user is spending money, positive if the user is receiving money.
      the description should be a string. it should be a concise and meaningful description for the transaction written in the user's original language. write it all lowercase. rewrite it better.
      the date should be a string in the format YYYY-MM-DD. if no date is provided, use today's date. today is #{Date.today}.

      use the user's input to gain insights on the transaction amount, date and description.
    TEXT
  end
end
