class Transaction < ApplicationRecord
  belongs_to :user

  enum :status, { pending: 0, processed: 1, failed: 2 }, default: :pending

  validates :raw_input, presence: true
  validates :status, presence: true

  validates :amount, :date, :description, presence: true, if: :processed?

  after_create_commit -> {
    broadcast_prepend_later_to [ user, :transactions ], target: "transactions_list"
  }
  after_update_commit -> {
    broadcast_replace_later_to [ user, :transactions ]
    broadcast_replace_later_to [ user, :cashflow_summary ], partial: "transactions/cashflow_summary", locals: { user: user }, target: "cashflow_card"
    broadcast_replace_later_to [ user, :cashflow_detail ], partial: "transactions/cashflow_detail", locals: { user: user }, target: "cashflow_card"
  }
  after_destroy_commit -> {
    broadcast_remove_to [ user, :transactions ]
    broadcast_replace_to [ user, :cashflow_summary ], partial: "transactions/cashflow_summary", locals: { user: user }, target: "cashflow_card"
    broadcast_replace_to [ user, :cashflow_detail ], partial: "transactions/cashflow_detail", locals: { user: user }, target: "cashflow_card"
  }

  scope :recent, -> { order(date: :desc) }
end
