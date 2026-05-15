class Api::V1::BranchesController < Api::V1::BaseController
  before_action :set_company, only: [ :index, :create ]
  before_action :set_branch,  only: [ :show, :update, :destroy ]

  # GET /api/v1/companies/:company_id/branches
  def index
    render json: @company.branches.order(:name)
  end

  # GET /api/v1/branches/:id
  def show
    render json: @branch
  end

  # POST /api/v1/companies/:company_id/branches
  def create
    branch = @company.branches.build(branch_params)
    if branch.save
      render json: branch, status: :created
    else
      render_errors(branch)
    end
  end

  # PATCH /api/v1/branches/:id
  def update
    if @branch.update(branch_params)
      render json: @branch
    else
      render_errors(@branch)
    end
  end

  # DELETE /api/v1/branches/:id
  def destroy
    @branch.destroy
    head :no_content
  end

  private

  def set_branch
    @branch = company_scope(Branch).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Sucursal no encontrada" }, status: :not_found
  end

  def branch_params
    params.permit(:name, :description, :city, :phone, :email)
  end
end
