class DocumentRequest < ApplicationRecord
  belongs_to :resident, class_name: "User", foreign_key: "user_id"

  has_one_attached :valid_id_image

  enum :document_type, { barangay_clearance: 0, certificate_of_indigency: 1, certificate_of_residency: 2, good_moral_character: 3, certificate_of_income: 4, certificate_of_low_income: 5 }
  enum :status, { pending: 0, processing: 1, rejected: 2, ready_to_pickup: 3 }, default: :pending
  enum :valid_id_type, { national_id: 0, drivers_license: 1, passport: 2, philhealth: 3 }

  store_accessor :custom_fields, :years_of_residency, :monthly_income, :job

  validates :tracking_number, presence: true, uniqueness: true
  validates :document_type, :status, :purpose, :valid_id_type, presence: true
  validates :valid_id_image, presence: true

  validates :years_of_residency, presence: true, numericality: { only_integer: true, greater_than: 0 }, if: :certificate_of_residency?
  validates :monthly_income, :job, presence: true, if: :certificate_of_income?

  before_validation :generate_tracking_number

  private
    def generate_tracking_number
      self.tracking_number = "BRGY-DOC-#{Time.current.year}-#{SecureRandom.alphanumeric(8).upcase}"
    end
end
