class Api::V1::CustomersController < Api::V1::BaseController
  before_action :set_company,  only: [ :index, :create ]
  before_action :set_customer, only: [ :show, :update, :destroy ]

  # GET /api/v1/companies/:company_id/customers
  def index
    customers = @company.customers.order(:name)
    customers = customers.where("name ILIKE ?", "%#{params[:q]}%") if params[:q].present?
    render json: customers
  end

  # GET /api/v1/customers/:id
  def show
    render json: @customer
  end

  # POST /api/v1/companies/:company_id/customers
  def create
    customer = @company.customers.build(customer_params)
    if customer.save
      render json: customer, status: :created
    else
      render_errors(customer)
    end
  end

  # PATCH /api/v1/customers/:id
  def update
    if @customer.update(customer_params)
      render json: @customer
    else
      render_errors(@customer)
    end
  end

  # DELETE /api/v1/customers/:id
  def destroy
    @customer.destroy
    head :no_content
  end

  private

  def set_customer
    @customer = company_scope(Customer).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Cliente no encontrado" }, status: :not_found
  end

  def customer_params
    params.permit(:name, :phone, :email, :address, :city, :contact_name, :contact_phone, :notes)
  end
end
