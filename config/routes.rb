Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      # Auth (sin autenticación)
      post  "auth/register", to: "auth#register"
      post  "auth/login",    to: "auth#login"
      get   "auth/me",       to: "auth#me"
      patch "auth/profile",  to: "auth#update_profile"
      patch "auth/password", to: "auth#change_password"

      get "proxy/image", to: "proxy#image"

      # Recursos (autenticados)
      resources :companies do
        resources :branches,  shallow: true
        resources :products,  shallow: true do
          collection do
            post   :bulk_upload
            post   :upload_one
            post   :import
            get    :export
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
          end
        end
      end
    end
  end
end
