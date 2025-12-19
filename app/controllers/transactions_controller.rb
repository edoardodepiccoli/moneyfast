class TransactionsController < ApplicationController
  before_action :authenticate_user!
  def index
    @transactions = current_user.transactions.recent
    @new_transaction = current_user.transactions.build
  end

  def create
    @transaction = current_user.transactions.build(transaction_params)
    @transaction.status = :pending

    if @transaction.save
      ProcessTransactionJob.perform_later(@transaction.id)

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to transactions_path }
      end
    end
  end

  private

  def transaction_params
    params.require(:transaction).permit(:raw_input)
  end
end
