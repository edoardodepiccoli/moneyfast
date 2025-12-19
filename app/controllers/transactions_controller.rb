class TransactionsController < ApplicationController
  before_action :authenticate_user!
  def index
    @transactions = current_user.transactions.recent
    @new_transaction = current_user.transactions.build

    # Calculate monthly cashflow
    processed_transactions = current_user.transactions.processed
    @monthly_cashflow = processed_transactions
      .group_by { |t| t.date.beginning_of_month }
      .transform_values { |transactions| transactions.sum(&:amount) }
      .sort_by { |month, _| month }
      .reverse
      .to_h

    @total_cashflow = processed_transactions.sum(&:amount)
  end

  def create
    @transaction = current_user.transactions.build(transaction_params)
    @transaction.status = :pending

    if @transaction.save
      ProcessTransactionJob.perform_later(@transaction.id)

      respond_to do |format|
        format.turbo_stream
      end
    end
  end

  def destroy
    @transaction = current_user.transactions.find(params[:id])
    @transaction.destroy

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def transaction_params
    params.require(:transaction).permit(:raw_input)
  end
end
