class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @profile = current_user.profile
    @address = current_user.address

    full_name = [ @profile.first_name, @profile.middle_name, @profile.last_name, @profile.suffix ].compact_blank.join(" ")
    @resident_name = full_name.presence || "Resident Profile"

    @initials = [ @profile.first_name.first, @profile.last_name.first ].compact_blank.join.upcase.presence || "R"

    @full_address = [ @address.house_number, @address.street, @address.purok, @address.barangay, @address.city, @address.province ].compact_blank.join(", ")
  end

  def edit
    @profile = current_user.profile || current_user.build_profile
    @address = current_user.address || current_user.build_address
  end

  def update
    @profile = current_user.profile || current_user.build_profile
    @address = current_user.address || current_user.build_address

    ActiveRecord::Base.transaction do
      @profile.assign_attributes(profile_params)
      @address.assign_attributes(address_params)

      @profile.save!
      @address.save!
    end

    redirect_to profile_path, notice: "Your profile and address have been updated successfully."
  rescue ActiveRecord::RecordInvalid
    render :edit, status: :unprocessable_entity
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

    def address_params
      params.require(:address).permit(:house_number, :street, :purok, :barangay, :city, :province)
    end
end
