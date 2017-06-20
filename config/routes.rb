Rails.application.routes.draw do
  get 'home/index'

  post 'bugs/change_state'

  devise_for :users
  resources :projects do
    resources :bugs
  end
  
  root to: "home#index"
end
