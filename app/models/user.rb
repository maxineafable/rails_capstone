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

  has_many :assigned_barangay_concerns,
           class_name: "BarangayConcern",
           foreign_key: "assigned_staff_id"

  def barangay_staff?
    staff.present?
  end
end
