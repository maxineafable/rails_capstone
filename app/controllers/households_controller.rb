class HouseholdsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_staff!
  before_action :set_household, only: [ :show, :edit, :update, :destroy ]

  def show
    @members = @household.household_members
  end

  def new
    @household = Household.new
    @household.household_members.build
  end

  def create
    @household = Household.new(household_params)
    if @household.save
      redirect_to admin_residents_path, notice: "Household Census Record ##{@household.house_number} created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @household.update(household_edit_params)
      redirect_to household_path(@household), notice: "Household Census records modified successfully."
    else
      render :edit, status: :unprocessable_entity
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
          :citizenship, :occupation
        ]
      )
    end

    def authorize_staff!
      unless current_user.barangay_staff?
        redirect_to root_path, alert: "Unauthorized!"
      end
    end
end
