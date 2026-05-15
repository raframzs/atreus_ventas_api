class Api::V1::BaseController < ApplicationController
  private

  # Usado en acciones de colección (index, create) donde company_id viene en la URL
  def set_company
    @company = current_user.companies.find(params[:company_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Empresa no encontrada" }, status: :not_found
  end

  # Scope seguro para rutas shallow (show/update/destroy sin company_id en URL)
  def company_scope(model)
    model.where(company_id: current_user.company_ids)
  end
end
