module Api
  module V1
    module Admin
      class FeedbackController < ApplicationController
        before_action :require_super_admin!
        before_action :set_report, only: [:update, :destroy]

        def index
          reports = FeedbackReport.includes(:user).recent
          render json: reports.map { |r| admin_feedback_json(r) }
        end

        def update
          @report.update!(status: params[:status])
          render json: admin_feedback_json(@report)
        end

        def destroy
          @report.destroy!
          head :no_content
        end

        private

        def set_report
          @report = FeedbackReport.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: "No encontrado" }, status: :not_found
        end

        def admin_feedback_json(r)
          {
            id:              r.id,
            report_type:     r.report_type,
            message:         r.message,
            status:          r.status,
            context_url:     r.context_url,
            context_data:    r.context_data,
            screenshot_urls: r.screenshot_urls,
            created_at:      r.created_at,
            user: r.user ? { id: r.user.id, username: r.user.username, full_name: r.user.full_name } : nil
          }
        end
      end
    end
  end
end
