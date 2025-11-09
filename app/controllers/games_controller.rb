class GamesController < ApplicationController
  def index
    @q = Game.ransack(params[:q])

    # Optional “restrict by” filters (4.2)
    @games = @q.result
               .includes(:genres, :platforms, :developers)
    if params[:genre_id].present?
      @games = @games.joins(:genres).where(genres: { id: params[:genre_id] })
    end
    if params[:platform_id].present?
      @games = @games.joins(:platforms).where(platforms: { id: params[:platform_id] })
    end
    if params[:developer_id].present?
      @games = @games.joins(:developers).where(developers: { id: params[:developer_id] })
    end

    @games = @games.order(rating: :desc, released: :desc).page(params[:page]).per(20)
    @genres = Genre.order(:name)
    @platforms = Platform.order(:name)
    @developers = Developer.order(:name)
  end

  def show
    @game = Game.includes(:genres, :platforms, :developers, :reviews).find(params[:id])
  end
end
