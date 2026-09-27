class AddressesController < ApplicationController
  before_action :authenticate_user!

  def new
    @address = current_user.build_address
  end

  def create
    @address = current_user.build_address(address_params)
    if @address.save
      redirect_to root_path, notice: "Welcome! Your account onboarding is complete."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def address_params
      params.require(:address).permit(:house_number, :street, :purok, :barangay, :city, :province)
    end
end
