Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    base_origins = [ "http://localhost:5173", "http://localhost:8080", "http://localhost:3000" ]

    # Additional origins from env var (comma-separated)
    # Set ALLOWED_ORIGINS in Railway Variables, e.g.:
    #   https://atreus-ventas.netlify.app
    extra = ENV.fetch("ALLOWED_ORIGINS", "").split(",").map(&:strip).reject(&:empty?)

    # Also allow any *.netlify.app subdomain for preview deploys
    netlify_pattern = /\Ahttps:\/\/[a-zA-Z0-9\-]+\.netlify\.app\z/

    origins(*base_origins, *extra, netlify_pattern)

    resource "*",
             headers: :any,
             methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
             expose: [ "Content-Disposition" ]
  end
end
