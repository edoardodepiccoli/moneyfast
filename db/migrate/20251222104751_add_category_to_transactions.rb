class AddCategoryToTransactions < ActiveRecord::Migration[8.0]
  def up
    add_column :transactions, :category, :string, null: false, default: 'undefined'

    execute <<~SQL
      UPDATE transactions
      SET category = 'undefined'
      WHERE category IS NULL
    SQL
  end

  def down
    remove_column :transactions, :category
  end
end
