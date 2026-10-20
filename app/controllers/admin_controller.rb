class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_staff!

  def index
    @pending_docs_count = DocumentRequest.pending.count
    @ongoing_concerns_count = BarangayConcern.ongoing.count

    @docs_done_this_week = DocumentRequest
      .ready_to_pickup
      .where(updated_at: Time.current.all_week)
      .count

    @concerns_resolved_this_week = BarangayConcern
      .resolved
      .where(updated_at: Time.current.all_week)
      .count

    @total_residents_count = Profile.count

    @document_requests = DocumentRequest
      .includes(resident: [ :profile, :address ])
      .order(created_at: :desc)
      .to_a

    @barangay_concerns = BarangayConcern
      .includes(resident: [ :profile, :address ])
      .order(created_at: :desc)
      .to_a

    case params[:filter]
    when "documents"
      records_pool = @document_requests
    when "concerns"
      records_pool = @barangay_concerns
    else
      records_pool = @document_requests + @barangay_concerns
    end

    @recent_activities = records_pool.sort_by(&:created_at).reverse

    @pagy, @recent_activities = pagy(
      :offset,
      @recent_activities,
      limit: 2
    )
  end

  def document_requests
    query = DocumentRequest.joins(resident: [:profile, :address]).includes(resident: [:profile, :address])

    if params[:search].present?
      search_term = "%#{params[:search].downcase}%"
      query = query.where(
        "LOWER(profiles.first_name) LIKE :search OR " \
        "LOWER(profiles.last_name) LIKE :search",
        search: search_term
      )
    end

    if params[:status].present? && DocumentRequest.statuses.key?(params[:status])
      query = query.where(status: params[:status])
    end

    if params[:document_type].present?
      query = query.where(document_type: params[:document_type])
    end

    sort_direction = params[:sort_direction] == "asc" ? "ASC" : "DESC"
    query = query.order("document_requests.created_at #{sort_direction}")

    @pagy, @all_document_requests = pagy(:offset, query, items: 10)

    @total_docs = DocumentRequest.count
    @pending_docs_count = DocumentRequest.pending.count
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

    if params[:status].present? && BarangayConcern.statuses.key?(params[:status])
      query = query.where(status: params[:status])
    end

    if params[:category].present? && BarangayConcern.categories.key?(params[:category])
      query = query.where(category: params[:category])
    end

    sort_direction = params[:sort_direction] == "asc" ? "ASC" : "DESC"
    query = query.order("barangay_concerns.created_at #{sort_direction}")

    @pagy, @all_barangay_concerns = pagy(:offset, query, items: 10)

    @total_concerns = BarangayConcern.count
    @pending_concerns = BarangayConcern.pending.count
    @ongoing_concerns = BarangayConcern.ongoing.count
    @resolved_concerns = BarangayConcern.resolved.count
    @unactionable_concerns = BarangayConcern.unactionable.count
  end

  def residents
    @total_households = Household.count
    @new_household_count = Household.where(created_at: 30.days.ago..).count
    @puroks = Household.distinct.order(:purok).pluck(:purok)

    household_query = Household.left_joins(:household_members).includes(:household_members)

    if params[:search].present?
      term = "%#{ActiveRecord::Base.sanitize_sql_like(params[:search].strip.downcase)}%"
      household_query = household_query.where(
        "LOWER(households.house_number) LIKE :term OR " \
        "LOWER(households.street) LIKE :term OR " \
        "LOWER(households.purok) LIKE :term OR " \
        "LOWER(COALESCE(household_members.first_name, '')) LIKE :term OR " \
        "LOWER(COALESCE(household_members.last_name, '')) LIKE :term",
        term: term
      )
    end

    if params[:purok].present?
      household_query = household_query.where(purok: params[:purok])
    end

    case params[:filter]
    when "purok_1_3"
      household_query = household_query.where(purok: ["1", "2", "3", "Purok 1", "Purok 2", "Purok 3"])
    when "purok_4_5"
      household_query = household_query.where(purok: ["4", "5", "Purok 4", "Purok 5"])
    when "new"
      household_query = household_query.where(created_at: 30.days.ago..)
    end

    household_query = household_query.distinct
    household_query = case params[:sort]
    when "newest" then household_query.order(created_at: :desc)
    when "oldest" then household_query.order(created_at: :asc)
    when "purok" then household_query.order(purok: :asc, house_number: :asc)
    else household_query.order(house_number: :asc)
    end

    @filtered_household_count = household_query.count
    @pagy_households, @households = pagy(:offset, household_query, items: 10, page_param: :households_page)
  end

  def staffs
    query = User.joins(:staff).left_joins(:profile).includes(:profile, :staff).order("staffs.position ASC, profiles.last_name ASC")

    if params[:search].present?
      term = "%#{params[:search].strip.downcase}%"
      matching_positions = Staff.positions.select { |position, _value| position.humanize.downcase.include?(params[:search].strip.downcase) }.values
      query = query.where(
        "LOWER(COALESCE(profiles.first_name, '')) LIKE :term OR " \
        "LOWER(COALESCE(profiles.middle_name, '')) LIKE :term OR " \
        "LOWER(COALESCE(profiles.last_name, '')) LIKE :term OR " \
        "LOWER(users.email) LIKE :term OR staffs.position IN (:positions)",
        term: term,
        positions: matching_positions.presence || [-1]
      )
    end

    @staffs = query
    @staff_count = @staffs.count
  end

  private
    def authorize_staff!
      unless current_user.barangay_staff?
        redirect_to root_path, alert: "Unauthorized!"
      end
    end
end
