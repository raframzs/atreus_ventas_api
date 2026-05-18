class ProcessFeedbackScreenshotJob < ApplicationJob
  queue_as :default
  self.log_arguments = false

  def perform(feedback_report_id, file_content, filename, content_type)
    report = FeedbackReport.find_by(id: feedback_report_id)
    return unless report && R2_CLIENT

    ext = File.extname(filename).presence || ".jpg"
    key = "feedback/#{feedback_report_id}/#{SecureRandom.uuid}#{ext}"

    R2_CLIENT.put_object(
      bucket:       R2_BUCKET,
      key:          key,
      body:         Base64.strict_decode64(file_content),
      content_type: content_type
    )

    url = "#{R2_PUBLIC_URL}/#{key}"
    report.update_column(:screenshot_urls, report.screenshot_urls + [url])
  rescue Aws::S3::Errors::ServiceError => e
    Rails.logger.error "[R2] Error subiendo screenshot de feedback #{feedback_report_id}: #{e.message}"
    raise
  end
end
