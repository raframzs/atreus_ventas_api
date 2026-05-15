module Api
  module V1
    module Admin
      class StatsController < ApplicationController
        before_action :require_super_admin!

        def index
          render json: {
            total_companies:  Company.count,
            total_users:      User.where(super_admin: false).count,
            sales_this_month: Sale.where("created_at >= ?", Time.current.beginning_of_month).count,
          }
        end
      end
    end
  end
end
