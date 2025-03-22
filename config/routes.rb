Rails.application.routes.draw do
  devise_for :users
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "articles#index"
  resources :articles, except: [:edit, :update, :destroy]
  post 'articles/submit'
  post 'articles/reject'
  post 'articles/approve'
  post 'articles/resubmit'
  post 'articles/archive'
  post 'articles/publish'
  post 'articles/make_visible'
  post 'articles/make_invisible'
end
