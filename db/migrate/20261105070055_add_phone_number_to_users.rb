class AddPhoneNumberToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :phone_number, :string
    add_index :users, :phone_number, unique: true

    # unrestrict email when register
    change_column_null :users, :email, true
  end
end
