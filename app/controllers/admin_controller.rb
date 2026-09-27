class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_staff!

  def index
    @all_document_requests = DocumentRequest.order(created_at: :desc)
    @all_barangay_concerns = BarangayConcern.order(created_at: :desc)
  end

  private
    def authorize_staff!
      unless current_user.barangay_staff?
        redirect_to root_path, alert: "Unauthorized!"
      end
    end
end
