class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_staff!

  def index
    @all_document_requests = DocumentRequest.order(created_at: :desc)
    @all_barangay_concerns = BarangayConcern.order(created_at: :desc)
    
    @pending_docs_count = DocumentRequest.pending.count
    @ongoing_concerns_count = BarangayConcern.ongoing.count
    
    @docs_done_this_week = DocumentRequest.ready_to_pickup.where(updated_at: Time.current.all_week).count
    @concerns_resolved_this_week = BarangayConcern.resolved.where(updated_at: Time.current.all_week).count

    @total_residents_count = Profile.count
  end

  def document_requests
    @all_document_requests = DocumentRequest.order(created_at: :desc)

    @total_docs = DocumentRequest.count
    @processing_docs = DocumentRequest.processing.count
    @rejected_docs = DocumentRequest.rejected.count
    @ready_pickup_docs = DocumentRequest.ready_to_pickup.count
  end

  def barangay_concerns
    @all_barangay_concerns = BarangayConcern.order(created_at: :desc)

    @total_concerns = BarangayConcern.count
    @pending_concerns = BarangayConcern.pending.count
    @ongoing_concerns = BarangayConcern.ongoing.count
    @resolved_concerns = BarangayConcern.resolved.count
    @unactionable_concerns = BarangayConcern.unactionable.count
  end
  
  private
    def authorize_staff!
      unless current_user.barangay_staff?
        redirect_to root_path, alert: "Unauthorized!"
      end
    end
end
