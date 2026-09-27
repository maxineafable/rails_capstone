class BarangayConcern < ApplicationRecord
  belongs_to :resident, class_name: "User", foreign_key: "user_id"

  has_one_attached :evidence_image

  enum :category, { peace_and_order: 0, infrastructure: 1, waste_management: 2, health_and_sanitation: 3, others: 4 }
  enum :status, { pending: 0, ongoing: 1, resolved: 2, unactionable: 3 }, default: :pending

  validates :tracking_number, presence: true, uniqueness: true
  validates :category, :status, :reason, :location, presence: true

  before_validation :generate_tracking_number

  private
    def generate_tracking_number
      self.tracking_number = "BRGY-#{Time.current.year}-#{SecureRandom.alphanumeric(8).upcase}"
    end
end
