class RemoveStaffRemarksFromDocumentRequests < ActiveRecord::Migration[8.1]
  def change
    remove_column :document_requests, :staff_remarks, :text
  end
end
