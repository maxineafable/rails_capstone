class StatusLog < ApplicationRecord
  belongs_to :loggable, polymorphic: true

  validates :status, presence: true

  def human_status
    loggable_class = loggable_type.constantize
    loggable_class.statuses.key(status)&.humanize&.upcase || "UNKNOWN"
  end
end
