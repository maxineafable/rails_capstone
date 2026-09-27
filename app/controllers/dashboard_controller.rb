class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @document_requests = current_user.document_requests.order(created_at: :desc)
    @barangay_concerns = current_user.barangay_concerns.order(created_at: :desc)
  end
end
