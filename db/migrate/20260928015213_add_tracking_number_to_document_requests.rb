class AddTrackingNumberToDocumentRequests < ActiveRecord::Migration[8.1]
  def change
    add_column :document_requests, :tracking_number, :string, null: false
  end
end
