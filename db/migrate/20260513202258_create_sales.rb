class CreateSales < ActiveRecord::Migration[8.1]
  def change
    create_table :sales do |t|
      t.references :company,  null: false, foreign_key: true
      t.references :branch,             foreign_key: true
      t.references :customer,           foreign_key: true
      t.bigint     :seller_id, null: false
      t.string     :status,    null: false, default: "draft"
      t.decimal    :discount,  precision: 14, scale: 2, null: false, default: 0
      t.decimal    :subtotal,  precision: 14, scale: 2, null: false, default: 0
      t.decimal    :total,     precision: 14, scale: 2, null: false, default: 0
      t.text       :notes
      t.string     :invoice_number
      t.datetime   :invoiced_at
      t.datetime   :sent_email_at
      t.datetime   :sent_whatsapp_at

      t.timestamps
    end

    add_index :sales, :seller_id
    add_index :sales, :status
    add_index :sales, :invoice_number, unique: true, where: "invoice_number IS NOT NULL"
    add_foreign_key :sales, :users, column: :seller_id
  end
end
