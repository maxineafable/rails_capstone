class HouseholdMembersController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_staff!
  before_action :set_household

  def new
    @household_member = @household.household_members.build
  end

  # POST /households/:household_id/household_members
  def create
    @household_member = @household.household_members.build(member_params)

    if @household_member.save
      redirect_to household_path(@household), notice: "New family member has been successfully added to Household ##{@household.house_number}."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def set_household
      @household = Household.find(params[:household_id])
    end

    def member_params
      params.require(:household_member).permit(
        :first_name, :middle_name, :last_name, :suffix,
        :birth_date, :birth_place, :sex, :civil_status,
        :citizenship, :occupation
      )
    end

    def authorize_staff!
      unless current_user.barangay_staff?
        redirect_to root_path, alert: "Unauthorized!"
      end
    end
end
