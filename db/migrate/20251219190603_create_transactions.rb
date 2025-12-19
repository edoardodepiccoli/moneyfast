class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :raw_input, null: false
      t.integer :status, null: false, default: 0

      t.date :date
      t.decimal :amount, precision: 10, scale: 2
      t.string :description, limit: 255

      t.timestamps
    end
  end
end
