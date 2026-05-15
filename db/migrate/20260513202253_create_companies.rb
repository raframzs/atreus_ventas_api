class CreateCompanies < ActiveRecord::Migration[8.1]
  def change
    create_table :companies do |t|
      t.string  :name,             null: false
      t.string  :currency,         null: false, default: "COP"
      t.integer :invoice_seq,      null: false, default: 0
      t.text    :whatsapp_template

      t.timestamps
    end
  end
end
