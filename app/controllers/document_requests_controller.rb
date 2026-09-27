class DocumentRequestsController < ApplicationController
  before_action :authenticate_user!

  def select_type
  end

  def new
    if DocumentRequest.document_types.keys.include?(params[:document_type])
      @document_type = params[:document_type]
      @document_request = current_user.document_requests.build(document_type: @document_type)
    else
      redirect_to select_document_type_path, alert: "Invalid document type selected."
    end
  end

  def create
    @document_request = current_user.document_requests.build(document_request_params)
    @document_request.status = :pending

    if @document_request.save
      redirect_to root_path, notice: "Your document request has been submitted successfully to the Barangay Staff."
    else
      @document_type = @document_request.document_type
      render :new, status: :unprocessable_entity
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

end
