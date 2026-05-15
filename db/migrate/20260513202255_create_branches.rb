class CreateBranches < ActiveRecord::Migration[8.1]
  def change
    create_table :branches do |t|
      t.references :company, null: false, foreign_key: true
      t.string :name, null: false
      t.string :description
      t.string :city
      t.string :phone
      t.string :email

      t.timestamps
    end
  end
end
