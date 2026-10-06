class BarangayConcern < ApplicationRecord
  extend Pagy::Search

  belongs_to :resident, class_name: "User", foreign_key: "user_id"
  belongs_to :assigned_staff, class_name: "User", optional: true

  has_one_attached :evidence_image
  has_many :status_logs, as: :loggable, dependent: :destroy

  enum :category, { peace_and_order: 0, infrastructure: 1, waste_management: 2, health_and_sanitation: 3, others: 4 }
  enum :status, { pending: 0, ongoing: 1, resolved: 2, unactionable: 3 }, default: :pending

  attr_accessor :staff_remarks

  validates :tracking_number, presence: true, uniqueness: true
  validates :category, :status, :reason, :location_description, presence: true

  validate :sequential_status, on: :update

  before_validation :generate_tracking_number, on: :create
  after_save :log_status_change, if: :saved_change_to_status?
  before_save :resolved_timestamp, if: -> { persisted? && :will_save_change_to_status? }

  private
    def generate_tracking_number
      self.tracking_number = "BRGY-CON-#{Time.current.year}-#{SecureRandom.alphanumeric(8).upcase}"
    end

    def log_status_change
      status_logs.create!(
        status: self.class.statuses[status],
        staff_remarks: staff_remarks
      )
    end

    def sequential_status
      if status_changed?
        old_status_value = self.class.statuses[status_was]
        new_status_value = self.class.statuses[status]

        if new_status_value < old_status_value
          errors.add(:status, "cannot go backward to a previous step.")
        elsif old_status_value >= 2
          errors.add(:status, "cannot be changed once it is already resolved or unactionable.")
        end
      end
    end

    def resolved_timestamp
      if resolved?
        self.resolved_at = Time.current
      end
    end
end
