class GenresController < ApplicationController
  def show
    @genre = Genre.find(params[:id])
    @games = @genre.games.order(rating: :desc).page(params[:page]).per(20)
  end
end
