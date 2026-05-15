module Api
  module V1
    module Admin
      class UsersController < ApplicationController
        before_action :require_super_admin!

        def impersonate
          target = User.find(params[:id])
          company = target.companies.first
          token = JwtService.encode({ user_id: target.id })
          render json: {
            token:   token,
            user:    {
              id:          target.id,
              username:    target.username,
              full_name:   target.full_name,
              email:       target.email,
              super_admin: target.super_admin,
            },
            company: company ? {
              id:                 company.id,
              name:               company.name,
              currency:           company.currency,
              invoice_seq:        company.invoice_seq,
              whatsapp_template:  company.whatsapp_template,
            } : nil,
          }, status: :ok
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Usuario no encontrado" }, status: :not_found
        end
      end
    end
  end
end
