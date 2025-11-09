Rails.application.routes.draw do
  get "developers/show"
  get "platforms/show"
  get "genres/show"
  get "games/index"
  get "games/show"
  root "pages#home"
  get "about", to: "pages#about"
  resources :games, only: [:index, :show]
  resources :genres, only: [:show]
  resources :platforms, only: [:show]
  resources :developers, only: [:show]
end
