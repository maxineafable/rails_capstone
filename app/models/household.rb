class Household < ApplicationRecord
  has_many :household_members, dependent: :destroy

  validates :house_number, :street, :purok, :date_accomplished, presence: true

  accepts_nested_attributes_for :household_members
end
