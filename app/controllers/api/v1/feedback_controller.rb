module Api
  module V1
    class FeedbackController < ApplicationController
      def create
        report = current_user.feedback_reports.new(feedback_params)

        if report.save
          Array(params[:screenshots]).each do |file|
            encoded = Base64.strict_encode64(file.read)
            ProcessFeedbackScreenshotJob.perform_later(
              report.id,
              encoded,
              file.original_filename,
              file.content_type
            )
          end

          render json: feedback_json(report), status: :created
        else
          render json: { errors: report.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

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
