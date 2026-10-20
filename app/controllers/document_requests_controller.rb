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
    @ready_requests = @all_document_requests.ready_to_pickup.count

    @document_requests = case params[:filter]
    when "pending" then @all_document_requests.pending
    when "processing" then @all_document_requests.processing
    when "ready_to_pickup" then @all_document_requests.ready_to_pickup
    when "claimed" then @all_document_requests.claimed
    when "rejected" then @all_document_requests.rejected
    else @all_document_requests
    end
  end

  def show
    if current_user.barangay_staff?
      @document_request = DocumentRequest.find(params[:id])
    else
      @document_request = current_user.document_requests.find(params[:id])
    end

    @intent = params[:intent]
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
    @document_request = current_user.document_requests.build(attributes)

    if uploaded_id.respond_to?(:tempfile)
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
    @document_request = current_user.document_requests.build(document_request_params)
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
        :years_of_residency,
        :monthly_income,
        :job
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
