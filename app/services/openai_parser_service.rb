class OpenaiParserService
  def initialize(raw_input)
    @raw_input = raw_input
    @client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"] || ENV.fetch("OPENAI_API_KEY"))
  end

  CATEGORIES = %w[
    housing
    utilities
    food
    transport
    health
    shopping
    subscriptions
    education
    entertainment
    travel
    family
    gifts
    fees
    taxes
    other_expense
    salary
    freelance
    business
    investments
    refunds
    gifts_received
    other_income
    transfer
    cash_withdrawal
    cash_deposit
    adjustment
  ].freeze


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
      - "category": (string one of the following: #{CATEGORIES.join(', ')}). If no category is provided, use 'undefined'.

      the amount should be a float. it should be negative if the user is spending money, positive if the user is receiving money.
      the description should be a string. it should be a concise and meaningful description for the transaction written in the user's original language. write it all lowercase. rewrite it better.
      the date should be a string in the format YYYY-MM-DD. if no date is provided, use today's date. today is #{Date.today}.
      the category should be a string one of the following: #{CATEGORIES.join(', ')}. if no category is provided, use 'undefined'.

      use the user's input to gain insights on the transaction amount, date and description.
    TEXT
  end
end
