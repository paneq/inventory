class CreateChanges < ActiveRecord::Migration
  def change
    create_table :changes do |t|
      t.string  :identifier, null: false

      t.integer :available_quantity, null: false
      t.integer :reserved_quantity, null: false
      t.integer :sold_quantity, null: false

      t.integer :available_quantity_diff, null: false
      t.integer :reserved_quantity_diff, null: false
      t.integer :sold_quantity_diff, null: false

      t.timestamps
    end

    add_index :changes, :identifier
  end
end
