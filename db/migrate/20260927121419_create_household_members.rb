class CreateHouseholdMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :household_members do |t|
      t.string :first_name, null: false
      t.string :middle_name
      t.string :last_name, null: false
      t.string :suffix
      t.date :birth_date, null: false
      t.string :birth_place, null: false
      t.integer :sex, null: false
      t.integer :civil_status, null: false
      t.string :citizenship
      t.string :occupation

      t.references :household, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end
  end
end
