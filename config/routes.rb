Rails.application.routes.draw do
  root 'users#home'
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }
  resources :users, only: [ :member ] do
  	get 'home'
    get :friendship
  end
  resources :relationships, only: [:create, :destroy]
end
