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
    # Update cashflow whenever a processed transaction is updated
    if processed?
      broadcast_replace_later_to [ user, :cashflow ], partial: "transactions/cashflow", locals: { user: user }, target: "cashflow_card"
    end
  }
  after_destroy_commit -> {
    broadcast_remove_to [ user, :transactions ]
    # Always update cashflow on destroy - the calculation only includes processed transactions anyway
    # Use synchronous broadcast to ensure it happens immediately
    broadcast_replace_to [ user, :cashflow ], partial: "transactions/cashflow", locals: { user: user }, target: "cashflow_card"
  }

  scope :recent, -> { order(date: :desc) }
end
