class CreateBarangayConcerns < ActiveRecord::Migration[8.1]
  def change
    create_table :barangay_concerns do |t|
      t.string :reason, null: false
      t.integer :category, null: false
      t.integer :status, null: false, default: 0
      t.text :resident_remarks
      t.text :staff_remarks

      t.datetime :resolved_at

      t.references :user, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end
  end
end
