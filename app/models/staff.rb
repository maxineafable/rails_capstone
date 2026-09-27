class Staff < ApplicationRecord
  belongs_to :user

  enum :position, { captain: 0, secretary: 1, councilor: 2 }

  validates :position, presence: true
end
