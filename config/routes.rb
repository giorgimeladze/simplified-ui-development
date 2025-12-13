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

  resources :comments, only: [:show, :edit, :update] do
    collection do
      get :pending_comments
    end
    
    member do
      get :reject_feedback
      post :approve, :reject, :delete, :restore
    end
  end

  resources :state_transitions, only: [:index]
  resources :events, only: [:index]
  
  resource :custom_template, only: [:show, :edit, :update] do
    # Section-specific show actions
    get 'show_article', to: 'custom_templates#show_article', as: :show_article
    get 'show_comment', to: 'custom_templates#show_comment', as: :show_comment
    get 'show_navigation', to: 'custom_templates#show_navigation', as: :show_navigation
    get 'show_article2', to: 'custom_templates#show_article2', as: :show_article2
    get 'show_comment2', to: 'custom_templates#show_comment2', as: :show_comment2
    
    # Section-specific edit actions
    get 'edit_article', to: 'custom_templates#edit_article', as: :edit_article
    get 'edit_comment', to: 'custom_templates#edit_comment', as: :edit_comment
    get 'edit_navigation', to: 'custom_templates#edit_navigation', as: :edit_navigation
    get 'edit_article2', to: 'custom_templates#edit_article2', as: :edit_article2
    get 'edit_comment2', to: 'custom_templates#edit_comment2', as: :edit_comment2
    
    # Section-specific update actions
    patch 'update_article', to: 'custom_templates#update_article', as: :update_article
    patch 'update_comment', to: 'custom_templates#update_comment', as: :update_comment
    patch 'update_navigation', to: 'custom_templates#update_navigation', as: :update_navigation
    patch 'update_article2', to: 'custom_templates#update_article2', as: :update_article2
    patch 'update_comment2', to: 'custom_templates#update_comment2', as: :update_comment2
    
    # Reset actions
    member do
      post :reset
      post :reset_article
      post :reset_comment
      post :reset_navigation
      post :reset_article2
      post :reset_comment2
    end
  end

  # Article2 and Comment2 routes (copies of Article and Comment routes)
  resources :article2s do
    collection do
      get :my_article2s
      get :article2s_for_review
      get :deleted_article2s
    end
    
    member do
      get :reject_feedback
      post :submit, :reject, :approve_private, :resubmit
      post :archive, :publish, :make_visible, :make_invisible
    end

    resources :comment2s, only: [:new, :create]
  end

  resources :comment2s, only: [:show, :edit, :update] do
    collection do
      get :pending_comment2s
    end
    
    member do
      get :reject_feedback
      post :approve, :reject, :delete, :restore
    end
  end

  get 'comments/:id/article', to: 'comments#index', as: :comment_article
  get 'comment2s/:id/article2', to: 'comment2s#index', as: :comment2_article2
end
