Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  # root "posts#index"

  namespace :api do
    namespace :v1 do
      get 'jwks', to: 'jwks#show'
      resources :users, only: [:show, :update] do
        collection do
          match :auto_complete, via: [:get, :post]
        end
        member do
          put  :change_password
          put  :preferences
          put  :avatar     # toggle gravatar
          post :avatar     # multipart upload
        end
      end
      namespace :admin do
        resources :tokens, only: [:create]
        resources :groups
        resources :users do
          member do
            put :suspend
            put :reactivate
          end
        end
      end
    end
  end
end


