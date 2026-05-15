class MakeProductBranchIdOptional < ActiveRecord::Migration[8.1]
  def change
    change_column_null :products, :branch_id, true
  end
end
