module Api
  module V1
    module Admin
      class CompaniesController < ApplicationController
        before_action :require_super_admin!
        before_action :set_company, only: [:show, :update, :destroy]

        def index
          companies = Company.includes(:members, :users).order(created_at: :desc)
          render json: companies.map { |c| company_json(c) }
        end

        def show
          render json: company_json(@company)
        end

        def update
          if @company.update(company_params)
            render json: company_json(@company)
          else
            render json: { errors: @company.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          @company.destroy!
          head :no_content
        end

        private

        def set_company
          @company = Company.includes(:members, :users).find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: "No encontrada" }, status: :not_found
        end

        def company_params
          params.require(:company).permit(:enabled)
        end

        def company_json(company)
          owner_member = company.members.find { |m| m.role == "owner" }
          owner = owner_member ? company.users.find { |u| u.id == owner_member.user_id } : nil
          {
            id:          company.id,
            name:        company.name,
            enabled:     company.respond_to?(:enabled) ? company.enabled : true,
            users_count: company.members.size,
            sales_count: company.respond_to?(:sales) ? company.sales.count : 0,
            created_at:  company.created_at,
            owner:       owner ? { id: owner.id, username: owner.username, full_name: owner.full_name } : nil,
          }
        end
      end
    end
  end
end
