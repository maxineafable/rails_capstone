class Address < ApplicationRecord
  belongs_to :user

  validates :house_number, :purok, :barangay, :city, :province, presence: true
end
