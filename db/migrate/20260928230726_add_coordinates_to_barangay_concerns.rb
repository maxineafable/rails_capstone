class AddCoordinatesToBarangayConcerns < ActiveRecord::Migration[8.1]
  def change
    rename_column :barangay_concerns, :location, :location_description

    add_column :barangay_concerns, :latitude, :decimal, precision: 10, scale: 6
    add_column :barangay_concerns, :longitude, :decimal, precision: 10, scale: 6
  end
end
