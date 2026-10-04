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
    query = DocumentRequest.joins(resident: [ :profile, :address ]).includes(resident: [ :profile, :address ])

    if params[:search].present?
      search_term = "%#{params[:search].downcase}%"
      query = query.where(
        "LOWER(profiles.first_name) LIKE :search OR " \
        "LOWER(profiles.last_name) LIKE :search",
        search: search_term
      )
    end

    # allowed_sort_columns = {
    #   "resident_name" => "profiles.last_name",
    #   "date"          => "document_requests.created_at"
    # }

    sort_direction = params[:sort_direction] == "asc" ? "ASC" : "DESC"
    query = query.order("document_requests.created_at #{sort_direction}")

    # sort_column = allowed_sort_columns[params[:sort]] || "document_requests.created_at"
    # sort_direction = %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"

    # query = query.order("#{sort_column} #{sort_direction}")

    @pagy, @all_document_requests = pagy(:offset, query, items: 10)

    @total_docs = DocumentRequest.count
    @processing_docs = DocumentRequest.processing.count
    @rejected_docs = DocumentRequest.rejected.count
    @ready_pickup_docs = DocumentRequest.ready_to_pickup.count
  end

  def barangay_concerns
    query = BarangayConcern.joins(resident: [ :profile, :address ]).includes(resident: [ :profile, :address ])

    if params[:search].present?
      search_term = "%#{params[:search].downcase}%"
      query = query.where(
        "LOWER(profiles.first_name) LIKE :search OR " \
        "LOWER(profiles.last_name) LIKE :search",
        search: search_term
      )
    end

    sort_direction = params[:sort_direction] == "asc" ? "ASC" : "DESC"
    query = query.order("barangay_concerns.created_at #{sort_direction}")

    # query = query.order("#{sort_column} #{sort_direction}")

    @pagy, @all_barangay_concerns = pagy(:offset, query, items: 10)




    # @all_barangay_concerns = BarangayConcern.order(created_at: :desc)

    @total_concerns = BarangayConcern.count
    @pending_concerns = BarangayConcern.pending.count
    @ongoing_concerns = BarangayConcern.ongoing.count
    @resolved_concerns = BarangayConcern.resolved.count
    @unactionable_concerns = BarangayConcern.unactionable.count
  end

  def residents
    @residents = User.includes(:profile, :address).order("profiles.last_name ASC")
  end

  def staffs
    @staffs = User.includes(:profile, :staff).where.associated(:staff).order("staffs.position ASC")
  end

  private
    def authorize_staff!
      unless current_user.barangay_staff?
        redirect_to root_path, alert: "Unauthorized!"
      end
    end
end
