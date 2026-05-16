class CreateAnnouncements < ActiveRecord::Migration[8.0]
  def change
    create_table :announcements do |t|
      t.string  :title
      t.text    :body,   null: false
      t.string  :kind,   null: false, default: "info"
      t.boolean :active, null: false, default: false

      t.timestamps
    end
  end
end
