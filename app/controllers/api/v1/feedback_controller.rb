module Api
  module V1
    class FeedbackController < ApplicationController
      def create
        report = current_user.feedback_reports.new(feedback_params)

        if report.save
          upload_screenshots(report, Array(params[:screenshots]))
          render json: feedback_json(report), status: :created
        else
          render json: { errors: report.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def upload_screenshots(report, files)
        return unless R2_CLIENT && files.any?

        urls = files.filter_map do |file|
          ext = File.extname(file.original_filename.to_s).presence || ".jpg"
          key = "feedback/#{report.id}/#{SecureRandom.uuid}#{ext}"
          R2_CLIENT.put_object(
            bucket:       R2_BUCKET,
            key:          key,
            body:         file.read,
            content_type: file.content_type
          )
          "#{R2_PUBLIC_URL}/#{key}"
        rescue Aws::S3::Errors::ServiceError => e
          Rails.logger.error "[R2] Error subiendo screenshot: #{e.message}"
          nil
        end

        report.update_column(:screenshot_urls, urls) if urls.any?
      end

      def feedback_params
        params.permit(:report_type, :message, :context_url, context_data: {})
      end

      def feedback_json(r)
        {
          id:              r.id,
          report_type:     r.report_type,
          message:         r.message,
          status:          r.status,
          context_url:     r.context_url,
          screenshot_urls: r.screenshot_urls,
          created_at:      r.created_at
        }
      end
    end
  end
end
