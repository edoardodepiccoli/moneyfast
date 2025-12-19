class ProcessTransactionJob < ApplicationJob
  queue_as :default

  def perform(transaction_id)
    transaction = Transaction.find(transaction_id)

    parsed_data = OpenaiParserService.new(transaction.raw_input).parse

    transaction.update!(
      amount: parsed_data["amount"],
      description: parsed_data["description"],
      date: parsed_data["date"],
      status: :processed
    )
  end
end
