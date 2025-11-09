class Game < ApplicationRecord
  has_many :game_genres, dependent: :destroy
  has_many :genres, through: :game_genres

  has_many :game_platforms, dependent: :destroy
  has_many :platforms, through: :game_platforms

  has_many :game_developers, dependent: :destroy
  has_many :developers, through: :game_developers

  has_many :reviews, dependent: :destroy

  validates :name, presence: true, length: { minimum: 2 }
  validates :slug, presence: true, uniqueness: true
end
