class Api::V1::SalesController < Api::V1::BaseController
  before_action :set_company, only: [ :index, :create ]
  before_action :set_sale,    only: [ :show, :update, :destroy, :confirm, :invoice, :cancel, :mark_sent, :share_pdf ]
  skip_before_action :authenticate_user!, only: [ :public_show ]

  # GET /api/v1/companies/:company_id/sales
  def index
    sales = @company.sales
      .includes(:customer, :branch, :sale_items)
      .order(created_at: :desc)

    sales = sales.where(status: params[:status])       if params[:status].present?
    sales = sales.where(branch_id: params[:branch_id]) if params[:branch_id].present?

    render json: sales.map { |s| sale_json(s) }
  end

  # GET /api/v1/sales/:id
  def show
    render json: sale_json(@sale)
  end

  # POST /api/v1/companies/:company_id/sales
  def create
    ActiveRecord::Base.transaction do
      sale = @company.sales.build(sale_params.except(:items))
      sale.seller = current_user
      sale.save!

      build_items(sale, params[:items] || [])
      sale.recompute_totals!

      render json: sale_json(sale), status: :created
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  # PATCH /api/v1/sales/:id
  def update
    unless @sale.status == "draft"
      render json: { error: "Solo se pueden editar ventas en borrador" }, status: :unprocessable_entity
      return
    end

    ActiveRecord::Base.transaction do
      @sale.update!(sale_params.except(:items))
      if params[:items].present?
        @sale.sale_items.destroy_all
        build_items(@sale, params[:items])
      end
      @sale.recompute_totals!
    end

    render json: sale_json(@sale)
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  # DELETE /api/v1/sales/:id
  def destroy
    @sale.destroy
    head :no_content
  end

  # POST /api/v1/sales/:id/confirm
  def confirm
    @sale.confirm!
    render json: sale_json(@sale)
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # POST /api/v1/sales/:id/invoice
  # Confirma + factura en un solo paso (el flujo habitual del frontend)
  def invoice
    ActiveRecord::Base.transaction do
      @sale.confirm! if @sale.status == "draft"
      @sale.invoice!
    end
    render json: sale_json(@sale)
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # POST /api/v1/sales/:id/cancel
  def cancel
    @sale.cancel!
    render json: sale_json(@sale)
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # POST /api/v1/sales/:id/mark_sent
  # Params: channel: "email" | "whatsapp"
  def mark_sent
    @sale.mark_sent!(params[:channel])
    render json: sale_json(@sale)
  end

  # POST /api/v1/sales/:id/share_pdf
  # Recibe el PDF generado en el browser, lo sube a R2 y devuelve la URL pública.
  # Si ya existe shared_pdf_url, lo reutiliza sin subir de nuevo.
  def share_pdf
    if @sale.shared_pdf_url.present?
      render json: { url: @sale.shared_pdf_url }
      return
    end

    pdf_file = params[:pdf]
    unless pdf_file.respond_to?(:read)
      render json: { error: "Falta el archivo PDF" }, status: :unprocessable_entity
      return
    end

    unless R2_CLIENT
      render json: { error: "Almacenamiento no configurado" }, status: :service_unavailable
      return
    end

    key = "invoices/#{@sale.id}.pdf"
    R2_CLIENT.put_object(
      bucket:       R2_BUCKET,
      key:          key,
      body:         pdf_file.read,
      content_type: "application/pdf"
    )

    url = "#{R2_PUBLIC_URL}/#{key}"
    @sale.update_column(:shared_pdf_url, url)

    render json: { url: url }
  rescue Aws::S3::Errors::ServiceError => e
    Rails.logger.error "[R2] Error subiendo PDF de venta #{@sale.id}: #{e.message}"
    render json: { error: "Error al subir el PDF" }, status: :service_unavailable
  end

  # GET /api/v1/sales/:id/public  — sin autenticación
  def public_show
    sale = Sale.includes(:customer, :branch, :sale_items, company: []).find_by(id: params[:id])
    unless sale&.shared_pdf_url.present?
      render json: { error: "No encontrado" }, status: :not_found
      return
    end

    render json: {
      id:             sale.id,
      invoice_number: sale.invoice_number,
      total:          sale.total,
      shared_pdf_url: sale.shared_pdf_url,
      company_name:   sale.company.name,
      customer_name:  sale.customer&.name,
      branch_name:    sale.branch&.name,
      invoiced_at:    sale.invoiced_at
    }
  end

  private

  def set_sale
    @sale = company_scope(Sale).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Venta no encontrada" }, status: :not_found
  end

  def sale_params
    params.permit(:branch_id, :customer_id, :status, :discount, :notes)
  end

  def build_items(sale, items_data)
    items_data.each do |item|
      product = sale.company.products.find_by(id: item[:product_id])
      sale.sale_items.create!(
        product:    product,
        name:       item[:name],
        sku:        item[:sku],
        qty:        item[:qty],
        unit_price: item[:unit_price],
        line_total: item[:qty].to_i * item[:unit_price].to_f,
        photo_url:  item[:photo_url] || product&.photo_url
      )
    end
  end

  def sale_json(sale)
    base = sale.as_json(
      include: {
        customer: { only: [ :id, :name, :phone, :email ] },
        branch:   { only: [ :id, :name ] },
        seller:   { only: [ :id, :username, :full_name ] }
      }
    )
    # Rename sale_items → items so the frontend accesses sale.items
    base["items"] = sale.sale_items.as_json(
      only: [ :id, :product_id, :name, :sku, :qty, :unit_price, :line_total, :photo_url ]
    )
    base["shared_pdf_url"] = sale.shared_pdf_url
    base
  end
end
