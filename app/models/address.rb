class Address < ApplicationRecord
  belongs_to :user

  validates :house_number, :street, :purok, :barangay, :city, :province, presence: true
end
