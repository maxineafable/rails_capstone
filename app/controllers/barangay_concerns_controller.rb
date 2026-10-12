class BarangayConcernsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_staff!, only: [ :edit, :update ]
  before_action :ensure_turbo_frame_request, only: [ :edit ]

  def index
    @barangay_concerns = current_user.barangay_concerns

    @total_concerns = @barangay_concerns.count
    @pending_concerns = @barangay_concerns.pending.count
    @ongoing_concerns = @barangay_concerns.ongoing.count
    @resolved_concerns = @barangay_concerns.resolved.count
    @unactionable_concerns = @barangay_concerns.unactionable.count
  end

  def show
    if current_user.barangay_staff?
      @barangay_concern = BarangayConcern.find(params[:id])
    else
      @barangay_concern = current_user.barangay_concerns.find(params[:id])
    end

    # @status_logs = @barangay_concern.status_logs.order(created_at: :asc)
  end

  def edit
    if current_user.barangay_staff?
      @barangay_concern = BarangayConcern.find(params[:id])
    end
  end

  def new
    @barangay_concern = current_user.barangay_concerns.build
  end

  def create
    @barangay_concern = current_user.barangay_concerns.build(barangay_concern_params)
    @barangay_concern.status = :pending

    if @barangay_concern.save
      redirect_to root_path, notice: "Your concern has been safely filed and reported to the Barangay Officials."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @barangay_concern = BarangayConcern.find(params[:id])

    if @barangay_concern.update(admin_barangay_concern_params)
      redirect_to @barangay_concern, notice: "Concern status updated successfully."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private
    def barangay_concern_params
      params.require(:barangay_concern).permit(:category, :reason, :resident_remarks, :evidence_image, :location_description, :latitude, :longitude)
    end

    def admin_barangay_concern_params
      params.require(:barangay_concern).permit(:status, :staff_remarks, :assigned_staff_id)
    end

    def authorize_staff!
      unless current_user.barangay_staff?
        redirect_to root_path, alert: "Unauthorized!"
      end
    end

    def ensure_turbo_frame_request
      # prevent user directly in example /doc-reqs/11
      unless turbo_frame_request? && turbo_frame_request_id == "remote_modal"
        destination = current_user.barangay_staff? ? admin_barangay_concerns_path : root_path

        redirect_to destination, alert: "Direct access to this page is not allowed."
      end
    end
end
