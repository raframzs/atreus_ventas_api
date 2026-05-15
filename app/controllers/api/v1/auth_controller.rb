class Api::V1::AuthController < ApplicationController
  skip_before_action :authenticate!, only: [ :register, :login ]

  # PATCH /api/v1/auth/profile
  def update_profile
    if current_user.update(profile_params)
      render json: { user: user_json(current_user) }
    else
      render_errors(current_user)
    end
  end

  # PATCH /api/v1/auth/password
  def change_password
    unless current_user.authenticate(params[:current_password])
      render json: { error: "Contraseña actual incorrecta" }, status: :unprocessable_entity
      return
    end
    if current_user.update(password: params[:password], password_confirmation: params[:password_confirmation])
      render json: { ok: true }
    else
      render_errors(current_user)
    end
  end

  # POST /api/v1/auth/register
  def register
    ActiveRecord::Base.transaction do
      user = User.new(user_params)

      unless user.save
        render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        return
      end

      company = Company.create!(
        name: params[:company_name].presence || "Tienda de #{user.full_name.split.first}",
        whatsapp_template: Company::DEFAULT_WHATSAPP_TEMPLATE
      )
      CompanyMember.create!(company: company, user: user, role: "owner")

      token = JwtService.encode({ user_id: user.id })
      render json: auth_response(token, user, company), status: :created
    end
  end

  # POST /api/v1/auth/login
  def login
    user = User.find_by(username: params[:username]&.downcase)

    unless user&.authenticate(params[:password])
      render json: { error: "Usuario o contraseña incorrectos" }, status: :unauthorized
      return
    end

    token = JwtService.encode({ user_id: user.id })
    company = user.companies.first
    render json: auth_response(token, user, company)
  end

  # GET /api/v1/auth/me
  def me
    company = current_user.companies.first
    render json: auth_response(nil, current_user, company).except(:token)
  end

  private

  def user_params
    params.permit(:username, :full_name, :email, :password, :password_confirmation)
  end

  def profile_params
    params.permit(:full_name, :email)
  end

  def user_json(user)
    { id: user.id, username: user.username, full_name: user.full_name, email: user.email, super_admin: user.super_admin }
  end

  def auth_response(token, user, company)
    {
      token: token,
      user: {
        id:          user.id,
        username:    user.username,
        full_name:   user.full_name,
        email:       user.email,
        super_admin: user.super_admin
      },
      company: company ? {
        id:                  company.id,
        name:                company.name,
        currency:            company.currency,
        invoice_seq:         company.invoice_seq,
        whatsapp_template:   company.whatsapp_template
      } : nil
    }.compact
  end
end
