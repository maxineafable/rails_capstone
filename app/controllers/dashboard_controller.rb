class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @document_requests = current_user.document_requests.order(created_at: :desc)
    @barangay_concerns = current_user.barangay_concerns.order(created_at: :desc)

    @active_requests = @document_requests.pending.count
    @active_reports = @barangay_concerns.pending.count

    @completed_records = @document_requests.ready_to_pickup.count + @barangay_concerns.resolved.count

    case params[:filter]
    when "documents"
      records_pool = @document_requests
    when "concerns"
      records_pool = @barangay_concerns
    else
      records_pool = @document_requests + @barangay_concerns
    end

    @recent_records = records_pool.sort_by(&:created_at).reverse.first(3)
  end
end
