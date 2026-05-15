class CreateSaleItems < ActiveRecord::Migration[8.1]
  def change
    create_table :sale_items do |t|
      t.references :sale,    null: false, foreign_key: true
      t.references :product,             foreign_key: true
      t.string  :name,       null: false
      t.string  :sku,        null: false
      t.integer :qty,        null: false
      t.decimal :unit_price, precision: 14, scale: 2, null: false
      t.decimal :line_total, precision: 14, scale: 2, null: false
      t.string  :photo_url

      t.timestamps
    end
  end
end
