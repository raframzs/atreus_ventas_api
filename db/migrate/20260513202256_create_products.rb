class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.references :company, null: false, foreign_key: true
      t.references :branch, null: false, foreign_key: true
      t.string  :sku,       null: false
      t.string  :name,      null: false
      t.text    :description
      t.string  :reference
      t.decimal :price,     precision: 14, scale: 2, null: false, default: 0
      t.integer :stock,     null: false, default: 0
      t.string  :photo_url
      t.boolean :is_active, null: false, default: true

      t.timestamps
    end

    add_index :products, [ :company_id, :sku ]
    add_index :products, :is_active
  end
end
