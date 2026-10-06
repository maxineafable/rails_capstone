class AddAssignedStaffToBarangayConcerns < ActiveRecord::Migration[8.1]
  def change
    add_reference :barangay_concerns, :assigned_staff, null: true, foreign_key: { to_table: :users }
  end
end
