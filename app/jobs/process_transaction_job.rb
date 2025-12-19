class ProcessTransactionJob < ApplicationJob
  queue_as :default

  def perform(transaction_id)
    transaction = Transaction.find(transaction_id)

    Rails.logger.info "Processing transaction #{transaction.id}"

    sleep 3

    transaction.update!(
      amount: 15.0,
      description: "mock description",
      date: Date.today,
      status: :processed
    )
  end
end
