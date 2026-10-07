class RegistrationsController < Devise::RegistrationsController
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected
    def configure_permitted_parameters
      profile_attributes = [ :first_name, :middle_name, :last_name, :suffix, :birth_date, :sex ]

      address_attributes = [ :house_number, :street, :purok, :barangay, :city, :province ]

      devise_parameter_sanitizer.permit(:sign_up, keys: [
        profile_attributes: profile_attributes,
        address_attributes: address_attributes
      ])
    end
end
