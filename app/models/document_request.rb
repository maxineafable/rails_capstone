class DocumentRequest < ApplicationRecord
  extend Pagy::Search

  belongs_to :resident, class_name: "User", foreign_key: "user_id"

  has_one_attached :valid_id_image
  has_many :status_logs, as: :loggable, dependent: :destroy
  has_many :resident_notifications, as: :notifiable, dependent: :destroy

  enum :document_type, { barangay_clearance: 0, certificate_of_indigency: 1, certificate_of_residency: 2, good_moral_character: 3, certificate_of_income: 4, certificate_of_low_income: 5 }
  enum :status, { pending: 0, processing: 1, rejected: 2, ready_to_pickup: 3, claimed: 4, approved: 5 }, default: :pending
  enum :valid_id_type, { national_id: 0, drivers_license: 1, passport: 2, philhealth: 3, postal_id: 4, umid: 5, prc: 6, school_id: 7 }

  store_accessor :custom_fields, :years_of_residency, :monthly_income, :job, :birth_place, :civil_status

  attr_accessor :staff_remarks

  validates :tracking_number, presence: true, uniqueness: true
  validates :document_type, :status, :purpose, :valid_id_type, presence: true
  validates :valid_id_image, presence: true
  validates :birth_place, :civil_status, presence: true, if: :barangay_clearance?, on: :create
  validates :civil_status, inclusion: { in: %w[single married widowed annulled legally_separated] }, if: :barangay_clearance?, on: :create

  validates :years_of_residency, presence: true, numericality: { only_integer: true, greater_than: 0 }, if: :certificate_of_residency?
  validates :monthly_income, :job, presence: true, if: :certificate_of_income?

  validate :sequential_status, on: :update

  before_validation :generate_tracking_number, on: :create
  after_save :log_status_change, if: :saved_change_to_status?
  after_update :notify_resident_of_status_change, if: :saved_change_to_status?

  private
    def generate_tracking_number
      self.tracking_number = "BRGY-DOC-#{Time.current.year}-#{SecureRandom.alphanumeric(8).upcase}"
    end

    def log_status_change
      status_logs.create!(
        status: self.class.statuses[status],
        staff_remarks: staff_remarks
      )
    end

    def notify_resident_of_status_change
      resident.resident_notifications.create!(
        notifiable: self,
        subject: document_type,
        status: status,
        body: "Nagbago ang status ng inyong kahilingan sa dokumento."
      )
    end

    def sequential_status
      if status_changed?
        allowed_transitions = {
          "pending" => %w[processing rejected],
          "processing" => %w[approved rejected],
          "approved" => %w[ready_to_pickup],
          "ready_to_pickup" => %w[claimed]
        }

        unless allowed_transitions.fetch(status_was, []).include?(status)
          errors.add(:status, "cannot transition from #{status_was.humanize} to #{status.humanize}.")
        end
      end
    end
end
