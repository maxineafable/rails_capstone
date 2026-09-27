class CreateHouseholds < ActiveRecord::Migration[8.1]
  def change
    create_table :households do |t|
      t.string :house_number, limit: 100, null: false
      t.string :street, limit: 100, null: false
      t.string :purok, limit: 10, null: false

      t.date :date_accomplished, null: false

      t.timestamps
    end
  end
end
