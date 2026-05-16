class AddScreenshotUrlsToFeedbackReports < ActiveRecord::Migration[8.1]
  def change
    add_column :feedback_reports, :screenshot_urls, :jsonb, default: []
  end
end
