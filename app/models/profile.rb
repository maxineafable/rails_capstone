class Profile < ApplicationRecord
  belongs_to :user

  enum :sex, { male: 0, female: 1 }

  validates :first_name, :last_name, :birth_date, :sex, presence: true
end
