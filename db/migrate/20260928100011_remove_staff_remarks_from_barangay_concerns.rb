class RemoveStaffRemarksFromBarangayConcerns < ActiveRecord::Migration[8.1]
  def change
    remove_column :barangay_concerns, :staff_remarks, :text
  end
end
