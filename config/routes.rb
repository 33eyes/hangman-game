Rails.application.routes.draw do
  get 'static_pages/about'

  resources :games
  resources :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  
  
  root 'users#index'
  
  
end
