class CreateProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :profiles do |t|
      t.string :first_name, null: false
      t.string :middle_name
      t.string :last_name, null: false
      t.string :suffix
      t.date :birth_date, null: false
      t.integer :sex, null: false

      t.references :user, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }

      t.timestamps
    end
  end
end
