class Household < ApplicationRecord
  has_many :household_members, dependent: :destroy

  validates :house_number, :street, :purok, :date_accomplished, presence: true
end
