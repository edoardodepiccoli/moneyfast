class Transaction < ApplicationRecord
  belongs_to :user

  enum :status, { pending: 0, processed: 1, failed: 2 }, default: :pending

  validates :raw_input, presence: true
  validates :status, presence: true

  validates :amount, :date, :description, presence: true, if: :processed?

  after_create_commit -> {
    broadcast_prepend_later_to [ user, :transactions ], target: "transactions_list"
    broadcast_prepend_later_to [ user, :transactions_compact ], partial: "transactions/transaction_compact", target: "transactions_list"
  }
  after_update_commit -> {
    broadcast_replace_later_to [ user, :transactions ]
    broadcast_replace_later_to [ user, :transactions_compact ], partial: "transactions/transaction_compact"
    broadcast_replace_later_to [ user, :cashflow_summary ], partial: "transactions/cashflow_summary", locals: { user: user }, target: "cashflow_card"
  }
  after_destroy_commit -> {
    broadcast_remove_to [ user, :transactions ]
    broadcast_remove_to [ user, :transactions_compact ]
    broadcast_replace_to [ user, :cashflow_summary ], partial: "transactions/cashflow_summary", locals: { user: user }, target: "cashflow_card"
  }

  scope :recent, -> { order(date: :desc) }
  scope :processed, -> { where(status: :processed) }
  scope :pending, -> { where(status: :pending) }
  scope :failed, -> { where(status: :failed) }
  scope :by_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :income, -> { where("amount > 0") }
  scope :expenses, -> { where("amount < 0") }
  scope :by_category, ->(category) { where(category: category) }
  scope :current_month, -> { where(date: Date.current.beginning_of_month..Date.current.end_of_month) }
  scope :future, -> { where("date > ?", Date.today) }
  scope :past, -> { where("date <= ?", Date.today) }

  def income?
    amount&.positive?
  end

  def expense?
    amount&.negative?
  end

  def scheduled?
    processed? && date.present? && date > Date.today
  end
end
