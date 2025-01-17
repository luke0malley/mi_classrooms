require 'sidekiq/web'

Rails.application.routes.draw do

  devise_for :users, controllers: {omniauth_callbacks: "users/omniauth_callbacks", sessions: "users/sessions"} do
    delete 'sign_out', :to => 'users/sessions#destroy', :as => :destroy_user_session
  end
  resources :rooms do
    resources :notes, module: :rooms
  end
  get 'rooms/:id/floor_plan', to: 'rooms#floor_plan'
  resources :notes
  
  match "toggle_visibile/:id" => "rooms#toggle_visibile", :via => [:get, :post], :as => :toggle_visibile
  
  get '/about', to: 'pages#about'
  get '/room_filters_glossary', to: 'pages#room_filters_glossary'
  root to: 'pages#index'
  get 'pages/index'
  
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  resources :buildings do
    resources :floors, module: :buildings
    resources :notes, module: :buildings
  end

  resources :announcements
  post 'announcements/:id/cancel', to: "announcements#cancel", as: 'announcements_cancel'

  get "legacy_crdb" => redirect("https://rooms.lsa.umich.edu")

  authenticate :user, lambda { |u| u.email == "dschmura@umich.edu" } do
    mount Sidekiq::Web => "/sidekiq"
  end

  resources :classrooms, only: [:index, :show]

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  get 'application/delete_file_attachment/:id', to: 'application#delete_file_attachment', as: :delete_file
  
end
