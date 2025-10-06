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
  get 'articles/my_articles'
  get 'articles/articles_for_review'
  get 'articles/deleted_articles'
  resources :articles, except: [:edit, :update]
  post 'articles/:id/submit', to: 'articles#submit'
  post 'articles/:id/reject', to: 'articles#reject'
  post 'articles/:id/approve_private', to: 'articles#approve_private'
  post 'articles/:id/resubmit', to: 'articles#resubmit'
  post 'articles/:id/archive', to: 'articles#archive'
  post 'articles/:id/publish', to: 'articles#publish'
  post 'articles/:id/make_visible', to: 'articles#make_visible'
  post 'articles/:id/make_invisible', to: 'articles#make_invisible'
end
