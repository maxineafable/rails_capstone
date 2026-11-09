class DocumentRequestsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_staff!, only: [ :update ]
  before_action :ensure_turbo_frame_request, only: [ :show ]

  def select_type
  end

  def index
    @all_document_requests = current_user.document_requests.order(created_at: :desc)
    @total_requests = @all_document_requests.count
    @pending_requests = @all_document_requests.pending.count
    @processing_requests = @all_document_requests.processing.count
    @approved_requests = @all_document_requests.approved.count
    @ready_requests = @all_document_requests.ready_to_pickup.count

    @document_requests = case params[:filter]
    when "pending" then @all_document_requests.pending
    when "processing" then @all_document_requests.processing
    when "approved" then @all_document_requests.approved
    when "ready_to_pickup" then @all_document_requests.ready_to_pickup
    when "claimed" then @all_document_requests.claimed
    when "rejected" then @all_document_requests.rejected
    else @all_document_requests
    end

    @pagy, @document_requests = pagy(:offset, @document_requests, limit: 5)
  end

  def show
    if current_user.barangay_staff?
      @document_request = DocumentRequest.find(params[:id])
    else
      @document_request = current_user.document_requests.find(params[:id])
    end

    @intent = params[:intent]
  end

  def residency_certificate
    unless current_user.barangay_staff?
      redirect_to root_path, alert: "Hindi awtorisadong mag-print ng sertipiko."
      return
    end

    @document_request = DocumentRequest.includes(resident: [ :profile, :address ]).find(params[:id])

    unless @document_request.certificate_of_residency? && @document_request.ready_to_pickup?
      redirect_to admin_document_requests_path, alert: "Para lamang sa Certificate of Residency na handa nang kunin ang sertipikong ito."
      return
    end

    @certificate_resident = @document_request.resident
    @certificate_profile = @certificate_resident.profile
    @certificate_address = @certificate_resident.address
    @certificate_name = [@certificate_profile.first_name, @certificate_profile.middle_name, @certificate_profile.last_name, @certificate_profile.suffix].compact_blank.join(" ")
    @certificate_salutation = @certificate_profile.male? ? "Mr." : "Ms."
    @certificate_issued_on = Time.zone.today

    render :residency_certificate, layout: false
  end

  def barangay_clearance
    unless current_user.barangay_staff?
      redirect_to root_path, alert: "Hindi awtorisadong mag-print ng barangay clearance."
      return
    end

    @document_request = DocumentRequest.includes(resident: [ :profile, :address ]).find(params[:id])

    unless @document_request.barangay_clearance? && (@document_request.approved? || @document_request.ready_to_pickup?)
      redirect_to admin_document_requests_path, alert: "Para lamang sa Barangay Clearance na naaprubahan o handa nang kunin ang dokumentong ito."
      return
    end

    @clearance_profile = @document_request.resident.profile
    @clearance_name = [ @clearance_profile.first_name, @clearance_profile.middle_name, @clearance_profile.last_name, @clearance_profile.suffix ].compact_blank.join(" ")
    @clearance_issued_on = Time.zone.today
    @clearance_number = "#{@document_request.id.to_s.rjust(6, '0')}-#{@clearance_issued_on.strftime('%y')}"

    render :barangay_clearance, layout: false
  end

  def certificate_of_income
    unless current_user.barangay_staff?
      redirect_to root_path, alert: "Hindi awtorisadong mag-print ng sertipiko ng kita."
      return
    end

    @document_request = DocumentRequest.includes(resident: [ :profile, :address ]).find(params[:id])

    unless @document_request.certificate_of_income? && (@document_request.approved? || @document_request.ready_to_pickup?)
      redirect_to admin_document_requests_path, alert: "Para lamang sa Certificate of Income na naaprubahan o handa nang kunin ang dokumentong ito."
      return
    end

    @income_profile = @document_request.resident.profile
    @income_address = @document_request.resident.address
    @income_name = [ @income_profile.first_name, @income_profile.middle_name, @income_profile.last_name, @income_profile.suffix ].compact_blank.join(" ")
    @income_issued_on = Time.zone.today

    render :certificate_of_income, layout: false
  end

  def good_moral_character
    unless current_user.barangay_staff?
      redirect_to root_path, alert: "Hindi awtorisadong mag-print ng Certificate of Good Moral Character."
      return
    end

    @document_request = DocumentRequest.includes(resident: [ :profile, :address ]).find(params[:id])

    unless @document_request.good_moral_character? && (@document_request.approved? || @document_request.ready_to_pickup?)
      redirect_to admin_document_requests_path, alert: "Para lamang sa Good Moral Character na naaprubahan o handa nang kunin ang dokumentong ito."
      return
    end

    @good_moral_profile = @document_request.resident.profile
    @good_moral_address = @document_request.resident.address
    @good_moral_name = [ @good_moral_profile.first_name, @good_moral_profile.middle_name, @good_moral_profile.last_name, @good_moral_profile.suffix ].compact_blank.join(" ")
    @good_moral_purok = @good_moral_address&.purok
    @good_moral_full_address = [
      @good_moral_address&.purok && "Purok #{@good_moral_address.purok}",
      @good_moral_address&.house_number,
      @good_moral_address&.street,
      @good_moral_address&.barangay,
      @good_moral_address&.city,
      @good_moral_address&.province
    ].compact_blank.join(", ")
    @good_moral_salutation = @good_moral_profile.male? ? "Mr." : "Ms."
    @good_moral_issued_on = Time.zone.today

    render :good_moral_character, layout: false
  end

  def certificate_of_indigency
    unless current_user.barangay_staff?
      redirect_to root_path, alert: "Hindi awtorisadong mag-print ng Certificate of Indigency."
      return
    end

    @document_request = DocumentRequest.includes(resident: [ :profile, :address ]).find(params[:id])

    unless @document_request.certificate_of_indigency? && (@document_request.approved? || @document_request.ready_to_pickup?)
      redirect_to admin_document_requests_path, alert: "Para lamang sa Certificate of Indigency na naaprubahan o handa nang kunin ang dokumentong ito."
      return
    end

    @indigency_profile = @document_request.resident.profile
    @indigency_address = @document_request.resident.address
    @indigency_name = [ @indigency_profile.first_name, @indigency_profile.middle_name, @indigency_profile.last_name, @indigency_profile.suffix ].compact_blank.join(" ")
    @indigency_address_line = [
      @indigency_address&.purok,
      @indigency_address&.house_number,
      @indigency_address&.street
    ].compact_blank.join(", ")
    @indigency_salutation = @indigency_profile.male? ? "Mr." : "Ms."
    @indigency_issued_on = Time.zone.today

    render :certificate_of_indigency, layout: false
  end

  def certificate_of_low_income
    unless current_user.barangay_staff?
      redirect_to root_path, alert: "Hindi awtorisadong mag-print ng Certificate of Low Income."
      return
    end

    @document_request = DocumentRequest.includes(resident: [ :profile, :address ]).find(params[:id])

    unless @document_request.certificate_of_low_income? && (@document_request.approved? || @document_request.ready_to_pickup?)
      redirect_to admin_document_requests_path, alert: "Para lamang sa Certificate of Low Income na naaprubahan o handa nang kunin ang dokumentong ito."
      return
    end

    @low_income_profile = @document_request.resident.profile
    @low_income_address = @document_request.resident.address
    @low_income_name = [ @low_income_profile.first_name, @low_income_profile.middle_name, @low_income_profile.last_name, @low_income_profile.suffix ].compact_blank.join(" ")
    @low_income_address_line = [
      @low_income_address&.purok,
      @low_income_address&.house_number,
      @low_income_address&.street
    ].compact_blank.join(", ")
    @low_income_salutation = @low_income_profile.male? ? "Mr." : "Ms."
    @low_income_issued_on = Time.zone.today

    render :certificate_of_low_income, layout: false
  end

  def submitted
    @document_request = current_user.document_requests.find(params[:id])
  end

  def new
    if DocumentRequest.document_types.keys.include?(params[:document_type])
      @document_type = params[:document_type]
      @document_request = current_user.document_requests.build(document_type: @document_type)

      @profile = current_user.profile
      @address = current_user.address
    else
      redirect_to select_document_type_path, alert: "Invalid document type selected."
    end
  end

  def review
    attributes = document_request_params
    uploaded_id = attributes.delete(:valid_id_image)
    camera_id = attributes.delete(:valid_id_camera)
    if uploaded_id.respond_to?(:tempfile) && uploaded_id.original_filename.blank?
      uploaded_id = camera_id
    elsif uploaded_id.blank?
      uploaded_id = camera_id
    end
    @document_request = current_user.document_requests.build(attributes)

    if uploaded_id.respond_to?(:tempfile) && uploaded_id.original_filename.present?
      blob = ActiveStorage::Blob.create_and_upload!(
        io: uploaded_id.tempfile,
        filename: uploaded_id.original_filename,
        content_type: uploaded_id.content_type,
        identify: true
      )
      @document_request.valid_id_image.attach(blob)
    elsif uploaded_id.present?
      @document_request.valid_id_image.attach(uploaded_id)
    end

    @document_type = @document_request.document_type
    @profile = current_user.profile
    @address = current_user.address

    if @document_request.valid?
      render :review
    else
      render :new, status: :unprocessable_entity
    end
  end

  def create
    attributes = document_request_params
    attributes.delete(:valid_id_camera)
    @document_request = current_user.document_requests.build(attributes)
    @document_request.status = :pending

    unless params[:accepted_declaration] == "1"
      @document_request.errors.add(:base, "Please confirm the sworn declaration before submitting.")
      @document_type = @document_request.document_type
      @accepted_declaration = false
      return render :review, status: :unprocessable_entity
    end

    if @document_request.save
      redirect_to submitted_document_request_path(@document_request), notice: "Your document request has been submitted successfully to the Barangay Staff."
    else
      @document_type = @document_request.document_type
      @accepted_declaration = false
      render :review, status: :unprocessable_entity
    end
  end

  def update
    @document_request = DocumentRequest.find(params[:id])

    if @document_request.update(admin_update_params)
      # @document_request.staff_remarks = nil

      redirect_to admin_document_requests_path, notice: "Document request status updated successfully."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private
    def document_request_params
      params.require(:document_request).permit(
        :document_type,
        :purpose,
        :resident_remarks,
        :staff_remarks,
        :valid_id_type,
        :valid_id_image,
        :valid_id_camera,
        :years_of_residency,
        :monthly_income,
        :job,
        :birth_place,
        :civil_status
      )
    end

    def admin_update_params
      params.require(:document_request).permit(:status, :staff_remarks)
    end

    def authorize_staff!
      unless current_user.barangay_staff?
        redirect_to root_path, alert: "Unauthorized!"
      end
    end

    def ensure_turbo_frame_request
      # prevent user directly in example /doc-reqs/11
      unless turbo_frame_request? && turbo_frame_request_id == "remote_modal"
        destination = current_user.barangay_staff? ? admin_document_requests_path : root_path

        redirect_to destination, alert: "Direct access to this page is not allowed."
      end
    end
end
