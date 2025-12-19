class Transaction < ApplicationRecord
  belongs_to :user

  enum :status, { pending: 0, processed: 1, failed: 2 }, default: :pending

  validates :raw_input, presence: true
  validates :status, presence: true

  validates :amount, :date, :description, presence: true, if: :processed?
end
