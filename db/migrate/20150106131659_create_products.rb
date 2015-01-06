class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products, id: false do |t|
      t.string  :identifier,         null: false
      t.integer :available_quantity, null: false
      t.integer :reserved_quantity,  null: false
      t.integer :sold_quantity,      null: false
      t.integer :store_quantity,     null: false

      t.timestamps
    end

    add_index :products, :identifier, unique: true
  end
end
