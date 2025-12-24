class AddIndexesToTransactions < ActiveRecord::Migration[8.0]
  def change
    add_index :transactions, [:user_id, :status, :date], name: "index_transactions_on_user_status_date"
    add_index :transactions, [:user_id, :date], name: "index_transactions_on_user_date"
  end
end

