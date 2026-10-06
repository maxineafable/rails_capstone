class AddRelationshipToHeadToHouseholdMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :household_members, :relationship_to_head, :string, null: false
  end
end
