class CreateFeedbackReports < ActiveRecord::Migration[8.1]
  def change
    create_table :feedback_reports do |t|
      t.references :user, null: false, foreign_key: true
      t.string :report_type, null: false, default: "other"
      t.text :message, null: false
      t.string :status, null: false, default: "pending"
      t.string :context_url
      t.jsonb :context_data, default: {}

      t.timestamps
    end

    add_index :feedback_reports, :status
    add_index :feedback_reports, :report_type
  end
end
