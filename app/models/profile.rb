class Profile < ApplicationRecord
  belongs_to :user
  has_one_attached :avatar

  enum :sex, { male: 0, female: 1 }

  validates :first_name, :last_name, :sex, presence: true
  validate :avatar_must_be_an_image

  private

  def avatar_must_be_an_image
    return unless avatar.attached?

    unless avatar.content_type.in?(%w[image/jpeg image/png image/webp])
      errors.add(:avatar, "must be a JPG, PNG, or WebP image")
    end

    if avatar.byte_size > 5.megabytes
      errors.add(:avatar, "must be smaller than 5 MB")
    end
  end
end
