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

  def self.ransackable_attributes(_auth_object = nil)
    %w[
      id
      name
      description
      slug
      rating
      rawg_id
      steam_appid
      released
      created_at
      updated_at
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[
      genres
      developers
      platforms
      reviews
    ]
  end
end
