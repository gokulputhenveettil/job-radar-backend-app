
require "sidekiq/web"
require "sidekiq/cron/web"

Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"


  namespace :api do
    namespace :v1 do

      # Authentication routes
      post "auth/login", to: "sessions#create"
      post "auth/signup", to: "registrations#create"
      delete "auth/logout", to: "sessions#destroy"
      get "auth/me", to: "sessions#show"

      resources :jobs, only: [:index] do
        post :poll, on: :collection
        member do
          patch :toggle_saved
          patch :toggle_applied
          patch :dismiss
        end
      end
    end
  end
end
