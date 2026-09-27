class CreateDocumentRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :document_requests do |t|
      t.integer :document_type, null: false
      t.integer :status, null: false, default: 0
      t.text :purpose, null: false
      t.text :resident_remarks
      t.text :staff_remarks

      t.integer :valid_id_type, null: false

      # for different inputs regarding to type of document requested
      t.jsonb :custom_fields, null: false, default: {}

      t.references :user, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end
  end
end
