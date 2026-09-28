class CreateStatusLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :status_logs do |t|
      t.references :loggable, polymorphic: true, null: false, index: true

      t.integer :status, null: false, default: 0
      t.text :staff_remarks

      t.timestamps
    end
  end
end
