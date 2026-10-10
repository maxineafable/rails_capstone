class HouseholdsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_staff!
  before_action :set_household, only: [ :show, :edit, :update, :destroy ]
  before_action :ensure_turbo_frame_request, only: [ :new, :edit ]

  def show
    @members = @household.household_members
  end

  def new
    @household = Household.new
    @household.household_members.build
  end

  def create
    @household = Household.new(household_params)

    first_member = @household.household_members.first
    first_member.relationship_to_head = "Head" if first_member

    if @household.save
      redirect_to admin_residents_path, notice: "Household Census Record ##{@household.house_number} created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @household.update(household_edit_params)
        format.html { redirect_to admin_residents_path, notice: "Household Census records modified successfully." }
        
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(ActionView::RecordIdentifier.dom_id(@household), 
                                  partial: "households/household_card", 
                                  locals: { household: @household }),
            turbo_stream.update("remote_modal", "")
          ]
        end
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @household.destroy
    redirect_to admin_residents_path, notice: "Household file wiped cleanly from Registry records."
  end


  private
    def set_household
      @household = Household.find(params[:id])
    end

    def household_edit_params
      params.require(:household).permit(:house_number, :street, :purok, :date_accomplished)
    end

    def household_params
      params.require(:household).permit(
        :house_number, :street, :purok, :date_accomplished,
        household_members_attributes: [
          :first_name, :middle_name, :last_name, :suffix,
          :birth_date, :birth_place, :sex, :civil_status,
          :citizenship, :occupation, :relationship_to_head
        ]
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
