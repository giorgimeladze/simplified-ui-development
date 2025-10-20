Rails.application.routes.draw do
  devise_for :users
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  get "up" => "rails/health#show", as: :rails_health_check
  root "articles#index"

  resources :articles do
    collection do
      get :my_articles
      get :articles_for_review
      get :deleted_articles
    end
    
    member do
      get :reject_feedback
      post :submit, :reject, :approve_private, :resubmit
      post :archive, :publish, :make_visible, :make_invisible
    end

    resources :comments, only: [:new, :create]
  end

  resources :comments, only: [:show, :destroy] do
    collection do
      get :pending_comments
    end
    
    member do
      get :reject_feedback
      post :approve, :reject, :delete, :restore
    end
  end

  resources :state_transitions, only: [:index]
  
  resource :custom_template, only: [:show, :edit, :update] do
    member do
      post :reset
    end
  end
end
