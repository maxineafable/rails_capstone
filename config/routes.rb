Rails.application.routes.draw do
  devise_for :users, :controllers => {:registrations => "registrations"}
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  resource :profile, only: [:show, :new, :create]
  resource :address, only: [:new, :create]

  get 'document_requests/new', to: 'document_requests#select_type', as: :select_document_type
  resources :document_requests, only: [:create, :show, :update] do
    collection do
      get ':document_type/new', to: 'document_requests#new', as: :new_type
    end
  end

  resources :barangay_concerns

  get '/admin', to: 'admin#index', as: :admin_dashboard

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "dashboard#index"
end
