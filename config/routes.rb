Rails.application.routes.draw do
  root "pages#home"
  get "about", to: "pages#about"
  resources :games, only: [:index, :show]
  resources :genres, only: [:show]
  resources :platforms, only: [:show]
  resources :developers, only: [:show]
end
