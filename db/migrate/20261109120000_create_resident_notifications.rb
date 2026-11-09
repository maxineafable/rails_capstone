class CreateResidentNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :resident_notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :notifiable, polymorphic: true, null: false
      t.string :subject, null: false
      t.string :status, null: false
      t.text :body, null: false
      t.datetime :read_at

      t.timestamps
    end

    add_index :resident_notifications, [ :user_id, :read_at, :created_at ], name: "index_resident_notifications_for_inbox"
  end
end
