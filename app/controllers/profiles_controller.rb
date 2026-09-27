class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @profile = current_user.profile
  end

  def new
    @profile = current_user.build_profile
  end

  def create
    @profile = current_user.build_profile(profile_params)
    if @profile.save
      redirect_to new_address_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    # def set_profile
    #   @profile = current_user.
    # end

    def profile_params
      params.require(:profile).permit(:first_name, :middle_name, :last_name, :suffix, :birth_date, :sex)
    end
end
