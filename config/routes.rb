Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "registrations" }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  resource :profile, only: [ :show, :create, :edit, :update ]

  get "document_requests/new", to: "document_requests#select_type", as: :select_document_type
  resources :document_requests, only: [ :index, :create, :show, :update ] do
    get :submitted, on: :member
    get :residency_certificate, on: :member
    collection do
      get ":document_type/new", to: "document_requests#new", as: :new_type
      post :review
    end
  end

  resources :barangay_concerns do
    get :submitted, on: :member
  end

  get "/admin", to: "admin#index", as: :admin_dashboard
  get "/admin/document_requests", to: "admin#document_requests", as: :admin_document_requests
  get "/admin/barangay_concerns", to: "admin#barangay_concerns", as: :admin_barangay_concerns
  get "/admin/residents", to: "admin#residents", as: :admin_residents
  get "/admin/staffs", to: "admin#staffs", as: :admin_staffs
  get "/admin/reports", to: "admin#reports", as: :admin_reports
  get "/admin/reports/export", to: "admin#reports_export", as: :admin_reports_export

  resources :households, except: [ :index ] do
    resources :household_members, only: [ :new, :create, :edit, :update ], as: :members
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  get "/dashboard", to: "dashboard#index", as: :dashboard

  # Public entry page; signed-in residents are sent to their dashboard.
  root "landingpage#index"
end
