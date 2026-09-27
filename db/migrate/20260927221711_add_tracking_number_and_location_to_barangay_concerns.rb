class AddTrackingNumberAndLocationToBarangayConcerns < ActiveRecord::Migration[8.1]
  def change
    add_column :barangay_concerns, :tracking_number, :string, null: false
    add_column :barangay_concerns, :location, :string, null: false
  end
end
