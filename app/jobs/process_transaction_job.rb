class ProcessTransactionJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :exponentially_longer, attempts: 3
  discard_on ActiveRecord::RecordNotFound

  def perform(transaction_id)
    transaction = Transaction.find(transaction_id)

    result = OpenaiParserService.new(transaction.raw_input).parse

    unless result.success?
      transaction.update!(status: :failed)
      Rails.logger.error "Failed to parse transaction #{transaction_id}: #{result.error}"
      raise StandardError, "OpenAI parsing failed: #{result.error}"
    end

    parsed_data = result.data

    # Validate parsed data before updating
    unless valid_parsed_data?(parsed_data)
      transaction.update!(status: :failed)
      raise StandardError, "Invalid parsed data structure"
    end

    transaction.update!(
      amount: parsed_data["amount"],
      description: parsed_data["description"],
      date: Date.parse(parsed_data["date"]),
      category: parsed_data["category"],
      status: :processed
    )
  rescue Date::Error => e
    transaction.update!(status: :failed)
    Rails.logger.error "Invalid date format for transaction #{transaction_id}: #{e.message}"
    raise
  rescue ActiveRecord::RecordInvalid => e
    transaction.update!(status: :failed)
    Rails.logger.error "Validation failed for transaction #{transaction_id}: #{e.message}"
    raise
  end

  private

  def valid_parsed_data?(data)
    data.is_a?(Hash) &&
      data["amount"].present? &&
      data["description"].present? &&
      data["date"].present? &&
      data["category"].present?
  end
end
