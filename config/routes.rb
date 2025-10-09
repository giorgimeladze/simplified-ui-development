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
  get 'comments/pending_comments'
  resources :articles do
    resources :comments, only: [:new, :create]
    
    # FSM transition routes for articles
    member do
      post :submit, :reject, :approve_private, :resubmit
      post :archive, :publish, :make_visible, :make_invisible
    end
  end

  resources :comments, only: [:show, :destroy] do
    # FSM transition routes for comments
    member do
      post :approve
      post :soft_delete
      post :restore
    end
  end
  post 'articles/:id/make_invisible', to: 'articles#make_invisible'
end
