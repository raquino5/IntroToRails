class Review < ApplicationRecord
  belongs_to :game
  validates :content, presence: true
  validates :rating, numericality: { allow_nil: true, only_integer: true, in: 0..100 }
end
