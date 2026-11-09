class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one :profile, dependent: :destroy
  has_one :address, dependent: :destroy
  has_one :staff, dependent: :destroy

  has_many :document_requests, dependent: :destroy
  has_many :barangay_concerns, dependent: :destroy
  has_many :resident_notifications, dependent: :destroy

  has_many :assigned_barangay_concerns,
           class_name: "BarangayConcern",
           foreign_key: "assigned_staff_id"

  accepts_nested_attributes_for :profile
  accepts_nested_attributes_for :address

  validates :profile, :address, presence: true

  validates :phone_number, presence: true, uniqueness: { case_sensitive: false }

  def barangay_staff?
    staff.present?
  end

  def email_required?
    false
  end

  def email_changed?
    false
  end

  def will_save_change_to_email?
    false
  end
end
