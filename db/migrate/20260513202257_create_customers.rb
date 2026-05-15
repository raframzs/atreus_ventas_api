class CreateCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :customers do |t|
      t.references :company, null: false, foreign_key: true
      t.string :name, null: false
      t.string :phone
      t.string :email
      t.string :address
      t.string :city
      t.string :contact_name
      t.string :contact_phone
      t.text :notes

      t.timestamps
    end
  end
end
