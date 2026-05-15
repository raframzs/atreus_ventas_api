class ApplicationController < ActionController::API
  before_action :authenticate!

  private

  def authenticate!
    token = request.headers["Authorization"]&.split(" ")&.last
    payload = JwtService.decode(token)
    @current_user = User.find_by(id: payload&.dig("user_id")) if payload
    render json: { error: "No autorizado" }, status: :unauthorized unless @current_user
  end

  def current_user = @current_user

  def require_super_admin!
    render json: { error: "No autorizado" }, status: :forbidden unless current_user&.super_admin?
  end

  def render_errors(record)
    render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
  end
end
