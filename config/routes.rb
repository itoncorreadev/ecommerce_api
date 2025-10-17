# frozen_string_literal: true

require 'sidekiq/web'

Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  mount Sidekiq::Web => '/sidekiq'

  resources :products
  resource :cart, controller: 'carts', only: %i[show create]
  delete 'cart/:product_id', to: 'carts#remove_item'
  post 'cart/add_item', to: 'carts#add_item'

  get 'up' => 'rails/health#show', as: :rails_health_check
  root 'rails/health#show'
end
