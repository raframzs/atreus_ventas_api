Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      # Auth (sin autenticación)
      post  "auth/register",        to: "auth#register"
      post  "auth/login",          to: "auth#login"
      get   "auth/me",             to: "auth#me"
      get   "auth/check_username", to: "auth#check_username"
      patch "auth/profile",  to: "auth#update_profile"
      patch "auth/password", to: "auth#change_password"

      get "proxy/image", to: "proxy#image"

      # Público autenticado — anuncio activo
      get "announcement", to: "announcements#show"

      # Admin (super_admin only)
      namespace :admin do
        get  :stats,     to: "stats#index"
        resources :companies, only: [:index, :show, :update, :destroy]
        resources :users, only: [] do
          member { post :impersonate }
        end
        resources :feedback, only: [:index, :update, :destroy]
        resource :announcement, only: [:show, :create, :update]
      end

      resources :feedback, only: [:create]

      # Recursos (autenticados)
      resources :companies do
        resources :branches,  shallow: true
        resources :products,  shallow: true do
          collection do
            post   :bulk_upload
            post   :upload_one
            post   :import
            get    :export
            get    :export_template
            delete :destroy_all
          end
        end
        resources :customers, shallow: true
        resources :sales,     shallow: true do
          member do
            post :confirm
            post :invoice
            post :cancel
            post :mark_sent
            post :share_pdf
          end
        end
      end
      # Ruta pública para ver PDF de una venta (sin auth)
      get "sales/:id/public", to: "sales#public_show"
    end
  end
end
