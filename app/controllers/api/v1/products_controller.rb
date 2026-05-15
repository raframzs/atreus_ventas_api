class Api::V1::ProductsController < Api::V1::BaseController
  before_action :set_company, only: [ :index, :create, :bulk_upload, :upload_one, :import, :export, :destroy_all ]
  before_action :set_product, only: [ :show, :update, :destroy ]

  # GET /api/v1/companies/:company_id/products
  def index
    cache_key = products_cache_key

    result = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      products = @company.products.includes(:branch).order(created_at: :desc)
      products = products.where(branch_id: params[:branch_id]) if params[:branch_id].present?
      products = products.active if params[:active] == "true"
      products.as_json(include: { branch: { only: [ :id, :name ] } })
    end

    render json: result
  end

  # GET /api/v1/products/:id
  def show
    render json: @product.as_json(include: { branch: { only: [ :id, :name ] } })
  end

  # POST /api/v1/companies/:company_id/products
  def create
    product = @company.products.build(product_params)
    if product.save
      invalidate_products_cache(@company.id)
      render json: product, status: :created
    else
      render_errors(product)
    end
  end

  # PATCH /api/v1/products/:id
  def update
    if @product.update(product_params)
      invalidate_products_cache(@product.company_id)
      render json: @product
    else
      render_errors(@product)
    end
  end

  # DELETE /api/v1/products/:id
  def destroy
    invalidate_products_cache(@product.company_id)
    @product.destroy
    head :no_content
  end

  # POST /api/v1/companies/:company_id/products/bulk_upload
  # Params: files[] (multipart), branch_id
  def bulk_upload
    branch = @company.branches.find(params[:branch_id])
    files  = Array(params[:files])

    if files.empty?
      render json: { error: "No se recibieron archivos" }, status: :bad_request
      return
    end

    created = files.map do |file|
      base = File.basename(file.original_filename, ".*")
      sku  = base.split(/[-_\s]/)[0].upcase

      product = @company.products.create!(
        branch:    branch,
        name:      base,
        sku:       sku,
        price:     0,
        stock:     0,
        is_active: true
      )
      ProcessProductPhotoJob.perform_later(product.id, file.read, file.original_filename, file.content_type)
      product
    end

    invalidate_products_cache(@company.id)
    render json: created, status: :created
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Sucursal no encontrada" }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  # POST /api/v1/companies/:company_id/products/upload_one
  # Crea un producto y sube su foto a R2 de forma síncrona.
  # El frontend llama esto N veces (una por archivo) y muestra progreso real.
  def upload_one
    branch = params[:branch_id].present? ? @company.branches.find(params[:branch_id]) : nil
    file   = params[:file]

    base = File.basename(file.original_filename, ".*")
    sku  = base.split(/[-_\s]/)[0].upcase

    product = @company.products.create!(
      branch:    branch,
      name:      base,
      sku:       sku,
      price:     0,
      stock:     0,
      is_active: true
    )

    if R2_CLIENT
      ext = File.extname(file.original_filename)
      key = "#{@company.id}/products/#{product.id}/#{SecureRandom.uuid}#{ext}"
      R2_CLIENT.put_object(bucket: R2_BUCKET, key: key, body: file.read, content_type: file.content_type)
      product.update_column(:photo_url, "#{R2_PUBLIC_URL}/#{key}")
    end

    invalidate_products_cache(@company.id)
    render json: product.as_json(include: { branch: { only: [ :id, :name ] } }), status: :created
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Sucursal no encontrada" }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  rescue Aws::S3::Errors::ServiceError => e
    Rails.logger.error "[R2] #{e.message}"
    render json: product.as_json(include: { branch: { only: [ :id, :name ] } }), status: :created
  end

  # POST /api/v1/companies/:company_id/products/import
  def import
    rows = Array(params[:rows])
    return render json: { error: "Sin filas" }, status: :bad_request if rows.empty?
    return render json: { error: "Máximo 500 filas por importación" }, status: :unprocessable_entity if rows.size > 500

    # Validación 1: duplicados en el archivo
    skus = rows.map { |r| r[:sku_actual].to_s.strip }.reject(&:blank?)
    dupes = skus.tally.select { |_, n| n > 1 }.keys
    if dupes.any?
      return render json: { error: "Refs. duplicadas en el archivo: #{dupes.join(', ')}" }, status: :unprocessable_entity
    end

    branch_names = @company.branches.pluck(:name)
    results = { updated: 0, created: 0, errors: [], warnings: [] }

    rows.each do |row|
      sku_actual = row[:sku_actual].to_s.strip
      next if sku_actual.blank?

      begin
        product = @company.products.find_by(sku: sku_actual)
        attrs   = {}

        sku_nuevo = row[:sku_nuevo].to_s.strip
        attrs[:sku] = sku_nuevo if sku_nuevo.present?

        name = row[:name].to_s.strip
        attrs[:name] = name if name.present?

        branch_name = row[:branch_name].to_s.strip
        if branch_name.present?
          branch = @company.branches.find_by(name: branch_name)
          # Validación 2: sucursal no encontrada → warning, no falla
          if branch
            attrs[:branch] = branch
          else
            results[:warnings] << "#{sku_actual}: sucursal '#{branch_name}' no encontrada, se ignoró"
          end
        end

        # Validación 3: precio negativo
        if row[:price].present?
          price = row[:price].to_f
          if price < 0
            results[:errors] << "#{sku_actual}: precio negativo (#{price})"
            next
          end
          attrs[:price] = price
        end

        stock = row[:stock]
        attrs[:stock] = [ stock.to_i, 0 ].max if stock.present?

        desc = row[:description].to_s.strip
        attrs[:description] = desc if desc.present?

        if product
          product.update!(attrs)
          results[:updated] += 1
        else
          create_attrs = { sku: sku_actual, name: sku_actual, is_active: true }.merge(attrs)
          @company.products.create!(create_attrs)
          results[:created] += 1
        end
      rescue => e
        results[:errors] << "#{sku_actual}: #{e.message}"
      end
    end

    invalidate_products_cache(@company.id)
    render json: results
  end

  # GET /api/v1/companies/:company_id/products/export
  # Images preserve aspect ratio up to PHOTO_MAX_W × PHOTO_MAX_H.
  # Row height is calculated dynamically from each image's actual display height.
  PHOTO_MAX_W = 155
  PHOTO_MAX_H = 195
  PX_TO_PT    = 0.75   # 96 DPI: 1px = 0.75pt
  ROW_PADDING = 16     # extra pts above/below image

  def export
    products   = @company.products.includes(:branch).order(:name)
    temp_files = []

    package = Axlsx::Package.new
    package.use_autowidth = false
    wb = package.workbook

    border = { style: :thin, color: "E2E8F0" }
    center = { horizontal: :center, vertical: :center, wrap_text: true }

    hdr   = wb.styles.add_style(bg_color: "0F172A", fg_color: "FFFFFF", b: true, sz: 11,
                                 alignment: center, border: { style: :thin, color: "334155" })
    ctr   = wb.styles.add_style(alignment: center, border: border)
    mono  = wb.styles.add_style(font_name: "Courier New", sz: 10,
                                 alignment: { horizontal: :center, vertical: :center }, border: border)
    price = wb.styles.add_style(font_name: "Courier New", sz: 10, num_fmt: 4,
                                 alignment: { horizontal: :center, vertical: :center }, border: border)

    wb.add_worksheet(name: "Catálogo") do |ws|
      ws.add_row(
        [ "Foto", "Referencia", "Nombre", "Sucursal", "Precio", "Stock", "Descripción" ],
        style: hdr, height: 26
      )

      products.each_with_index do |product, idx|
        row_index = idx + 1  # 0-based for start_at (header occupies index 0)

        # Fetch image and measure BEFORE add_row so row height matches image
        img_w, img_h, tmp = fetch_export_image(product)
        temp_files << tmp if tmp
        row_pts = tmp ? (img_h * PX_TO_PT + ROW_PADDING).ceil : 20

        ws.add_row(
          [ nil, product.sku, product.name, product.branch&.name || "Sin asignar",
            product.price, product.stock, product.description.to_s ],
          height: row_pts,
          style: [ nil, mono, ctr, ctr, price, mono, ctr ]
        )

        next unless tmp

        ws.add_image(image_src: tmp.path, noSelect: true, noMove: true) do |img|
          img.start_at 0, row_index
          img.width  = img_w
          img.height = img_h
        end
      end

      # Column A: 26 chars ≈ 182px — contains PHOTO_MAX_W=155px with ~27px margin
      ws.column_widths 26, 14, 30, 18, 12, 9, 40
    end

    date_str = Date.today.strftime("%d-%b-%Y").downcase
    data = package.to_stream.read

    send_data data,
      filename: "catalogo-#{@company.name.parameterize}_#{date_str}.xlsx",
      type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      disposition: "attachment"
  ensure
    temp_files.each { |f| f.close; f.unlink rescue nil }
  end

  # DELETE /api/v1/companies/:company_id/products/destroy_all
  def destroy_all
    count = @company.products.count
    @company.products.destroy_all
    invalidate_products_cache(@company.id)
    render json: { deleted: count }
  end

  private

  def set_product
    @product = company_scope(Product).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Producto no encontrado" }, status: :not_found
  end

  # Downloads the photo to a Tempfile and computes display size preserving aspect ratio.
  # Returns [width_px, height_px, tempfile] or [nil, nil, nil] if unavailable.
  # No resizing — caxlsx renders at the calculated display size for maximum sharpness.
  def fetch_export_image(product)
    return [ nil, nil, nil ] unless product.photo_url.present?

    ext = File.extname(URI.parse(product.photo_url).path).downcase.presence || ".jpg"
    ext = ".jpg" unless %w[.jpg .jpeg .png .gif .webp].include?(ext)

    tmp = Tempfile.new([ "exp_#{product.id}_", ext ])
    tmp.binmode
    tmp.write(URI.open(product.photo_url, read_timeout: 10).read)
    tmp.rewind

    w, h = image_display_size(tmp.path)
    [ w, h, tmp ]
  rescue => e
    Rails.logger.warn "[Export] imagen producto #{product.id}: #{e.message}"
    [ nil, nil, nil ]
  end

  # Scales image to fit PHOTO_MAX_W × PHOTO_MAX_H preserving aspect ratio.
  def image_display_size(path)
    info  = MiniMagick::Image.new(path)
    orig_w = info[:width].to_f
    orig_h = info[:height].to_f
    return [ PHOTO_MAX_W, PHOTO_MAX_H ] if orig_w.zero? || orig_h.zero?

    scale = [ PHOTO_MAX_W / orig_w, PHOTO_MAX_H / orig_h ].min
    [ (orig_w * scale).round, (orig_h * scale).round ]
  rescue => e
    Rails.logger.warn "[Export] image_display_size: #{e.message}"
    [ PHOTO_MAX_W, PHOTO_MAX_H ]
  end

  def product_params
    params.permit(:branch_id, :sku, :name, :description, :reference, :price, :stock, :photo_url, :is_active)
  end

  def products_cache_key
    parts = [ "products", @company.id ]
    parts << "branch:#{params[:branch_id]}" if params[:branch_id].present?
    parts << "active" if params[:active] == "true"
    parts.join(":")
  end

  def invalidate_products_cache(company_id)
    Rails.cache.delete_matched("products:#{company_id}*")
  end
end
