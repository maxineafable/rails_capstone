class CreateAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :addresses do |t|
      t.string :house_number, limit: 100, null: false
      t.string :street, limit: 100, null: false
      t.string :purok, limit: 10, null: false
      t.string :barangay, limit: 100, null: false
      t.string :city, limit: 100, null: false
      t.string :province, limit: 100, null: false

      t.references :user, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }

      t.timestamps
    end
  end
end
