class OpenaiParserService
  Result = Struct.new(:success?, :data, :error, keyword_init: true)

  def initialize(raw_input)
    @raw_input = raw_input
    @client = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_KEY"))
  end

  CATEGORIES = Moneyfast::CATEGORIES

  REQUIRED_KEYS = %w[amount description date category].freeze

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

    parsed_data = JSON.parse(response.dig("choices", 0, "message", "content"))

    unless validate_response(parsed_data)
      error_msg = "Invalid response structure: missing required keys"
      Rails.logger.error "OpenAI Parsing Error: #{error_msg}"
      return Result.new(success?: false, error: error_msg)
    end

    Result.new(success?: true, data: parsed_data)
  rescue StandardError => e
    Rails.logger.error "OpenAI Parsing Error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n") if Rails.env.development?
    Result.new(success?: false, error: e.message)
  end

  private

  def validate_response(data)
    return false unless data.is_a?(Hash)

    REQUIRED_KEYS.all? { |key| data.key?(key) }
  end

  private

  def system_prompt
    <<~TEXT
      parse the user's input into JSON with these keys:

      - "amount"
      - "description"
      - "date": (string YYYY-MM-DD). If no date is provided, use today's date. Today is #{Date.today}.
      - "category": (string one of the following: #{Moneyfast::CATEGORIES.join(', ')}). If no category is provided, use 'undefined'.

      the amount should be a float. it should be negative if the user is spending money, positive if the user is receiving money.
      the description should be a string. it should be a concise and meaningful description for the transaction written in the user's original language. write it all lowercase. rewrite it better.
      the date should be a string in the format YYYY-MM-DD. if no date is provided, use today's date. today is #{Date.today}.
      the category should be a string one of the following: #{Moneyfast::CATEGORIES.join(', ')}. if no category is provided, use 'undefined'.

      use the user's input to gain insights on the transaction amount, date and description.
    TEXT
  end
end
