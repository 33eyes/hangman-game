Rails.application.routes.draw do
  devise_for :users
  get 'static_pages/about'

  resources :users do
    resources :games
  end

#  resources :games
#  resources :users

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html


  root 'users#index'


end
