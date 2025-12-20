class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @transactions = current_user.transactions.recent.limit(10)
    @new_transaction = current_user.transactions.build
    @total_count = current_user.transactions.count
  end
end

