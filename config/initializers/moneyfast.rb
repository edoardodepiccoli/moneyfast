module Moneyfast
  # Transaction categories
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

  # Dashboard
  DASHBOARD_TRANSACTION_LIMIT = 10
end

