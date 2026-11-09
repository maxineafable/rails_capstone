class Address < ApplicationRecord
  belongs_to :user

  validates :purok, :barangay, :city, :province, presence: true
end
