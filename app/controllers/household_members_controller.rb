class HouseholdMembersController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_staff!
  before_action :set_household
  before_action :set_household_member, only: [ :edit, :update ]
  before_action :ensure_turbo_frame_request, only: [:new, :edit]

  def new
    @household_member = @household.household_members.build
  end

  # POST /households/:household_id/household_members
  def create
    @household_member = @household.household_members.build(member_params)

    if @household_member.save
      redirect_to admin_residents_path, notice: "New family member has been successfully added to Household ##{@household.house_number}."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @household_member.update(member_params)
      redirect_to admin_residents_path, notice: "Resident details for #{@household_member.first_name} have been updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_household
      @household = Household.find(params[:household_id])
    end

    def set_household_member
      @household_member = @household.household_members.find(params[:id])
    end

    def member_params
      params.require(:household_member).permit(
        :first_name, :middle_name, :last_name, :suffix,
        :birth_date, :birth_place, :sex, :civil_status,
        :citizenship, :occupation, :relationship_to_head
      )
    end

    def authorize_staff!
      unless current_user.barangay_staff?
        redirect_to root_path, alert: "Unauthorized!"
      end
    end

    def ensure_turbo_frame_request
      unless turbo_frame_request? && turbo_frame_request_id == "remote_modal"
        # Fallback redirect to index layout if accessed outside a turbo frame request loop
        redirect_to admin_residents_path, alert: "Please access this drawer form from the residents table panel."
      end
    end
end
