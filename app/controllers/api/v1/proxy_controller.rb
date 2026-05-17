class Api::V1::ProxyController < Api::V1::BaseController
  R2_HOSTS = [
    "pub-c6709a5122b5426ebebad1e0d3fc4ca6.r2.dev",
    "#{ENV.fetch('R2_ACCOUNT_ID', '')}.r2.cloudflarestorage.com",
  ].freeze

  # GET /api/v1/proxy/image?url=...
  def image
    url = params[:url].to_s

    unless allowed?(url)
      render json: { error: "URL no permitida" }, status: :forbidden
      return
    end

    io = URI.open(url, "rb", read_timeout: 10)
    data = io.read
    content_type = io.content_type.presence || "image/jpeg"
    send_data data, type: content_type, disposition: "inline"
  rescue => e
    render json: { error: e.message }, status: :bad_gateway
  end

  private

  def allowed?(url)
    uri = URI.parse(url)
    R2_HOSTS.any? { |h| uri.host == h }
  rescue URI::InvalidURIError
    false
  end
end
