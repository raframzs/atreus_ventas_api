class Api::V1::CompaniesController < Api::V1::BaseController
  before_action :find_company, only: [ :show, :update ]

  # GET /api/v1/companies
  def index
    render json: current_user.companies.order(:name)
  end

  # GET /api/v1/companies/:id
  def show
    render json: @company
  end

  # POST /api/v1/companies
  def create
    company = Company.transaction do
      c = Company.create!(company_params.merge(whatsapp_template: Company::DEFAULT_WHATSAPP_TEMPLATE))
      CompanyMember.create!(company: c, user: current_user, role: "owner")
      c
    end
    render json: company, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  # PATCH /api/v1/companies/:id
  def update
    if @company.update(company_params)
      render json: @company
    else
      render_errors(@company)
    end
  end

  private

  def find_company
    @company = current_user.companies.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Empresa no encontrada" }, status: :not_found
  end

  def company_params
    params.permit(:name, :currency, :whatsapp_template)
  end
end
