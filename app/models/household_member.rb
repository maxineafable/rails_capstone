class HouseholdMember < ApplicationRecord
  belongs_to :household

  enum :civil_status, { single: 0, married: 1, widowed: 2, divorced: 3, separated: 4 }, default: :single
  enum :sex, { male: 0, female: 1 }

  validates :first_name, :last_name, :birth_date, :birth_place, :sex, :civil_status, presence: true
end
