Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Component testing routes
  get "/components", to: "components#index", as: :components
  get "/components/phlex", to: "components#phlex", as: :components_phlex
  get "/components/typed_phlex", to: "components#typed_phlex", as: :components_typed_phlex
  get "/components/view_component", to: "components#view_component", as: :components_view_component
  get "/components/typed_view_component", to: "components#typed_view_component", as: :components_typed_view_component

  # Defines the root path route ("/")
  root "components#index"
end
