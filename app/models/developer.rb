class Developer < ApplicationRecord
  has_many :game_developers, dependent: :destroy
  has_many :games, through: :game_developers
  validates :name, :slug, presence: true
  validates :slug, uniqueness: true
end
