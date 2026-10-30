require "csv"

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
      limit: 5
    )
  end

  def document_requests
    query = DocumentRequest.left_joins(resident: [:profile, :address]).includes(resident: [:profile, :address])

    if params[:search].present?
      search_term = "%#{ActiveRecord::Base.sanitize_sql_like(params[:search].strip.downcase)}%"
      query = query.where(
        "LOWER(COALESCE(document_requests.tracking_number, '')) LIKE :search OR " \
        "LOWER(COALESCE(profiles.first_name, '')) LIKE :search OR " \
        "LOWER(COALESCE(profiles.last_name, '')) LIKE :search OR " \
        "LOWER(COALESCE(document_requests.purpose, '')) LIKE :search OR " \
        "LOWER(COALESCE(addresses.purok, '')) LIKE :search OR " \
        "LOWER(COALESCE(addresses.house_number, '')) LIKE :search OR " \
        "LOWER(COALESCE(addresses.street, '')) LIKE :search OR " \
        "LOWER(COALESCE(addresses.barangay, '')) LIKE :search OR " \
        "LOWER(COALESCE(addresses.city, '')) LIKE :search OR " \
        "LOWER(COALESCE(addresses.province, '')) LIKE :search",
        search: search_term
      )
    end

    if params[:status].present? && DocumentRequest.statuses.key?(params[:status])
      query = query.where(status: params[:status])
    end

    if params[:document_type].present? && DocumentRequest.document_types.key?(params[:document_type])
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
    query = BarangayConcern.left_joins(resident: [ :profile, :address ]).includes(resident: [ :profile, :address ])

    if params[:search].present?
      search_term = "%#{ActiveRecord::Base.sanitize_sql_like(params[:search].strip.downcase)}%"
      query = query.where(
        "LOWER(COALESCE(barangay_concerns.tracking_number, '')) LIKE :search OR " \
        "LOWER(COALESCE(profiles.first_name, '')) LIKE :search OR " \
        "LOWER(COALESCE(profiles.last_name, '')) LIKE :search OR " \
        "LOWER(COALESCE(barangay_concerns.location_description, '')) LIKE :search OR " \
        "LOWER(COALESCE(barangay_concerns.reason, '')) LIKE :search OR " \
        "LOWER(COALESCE(addresses.purok, '')) LIKE :search OR " \
        "LOWER(COALESCE(addresses.house_number, '')) LIKE :search OR " \
        "LOWER(COALESCE(addresses.street, '')) LIKE :search OR " \
        "LOWER(COALESCE(addresses.barangay, '')) LIKE :search OR " \
        "LOWER(COALESCE(addresses.city, '')) LIKE :search OR " \
        "LOWER(COALESCE(addresses.province, '')) LIKE :search",
        search: search_term
      )
    end

    if params[:status].present? && BarangayConcern.statuses.key?(params[:status])
      query = query.where(status: params[:status])
    end

    if params[:category].present? && BarangayConcern.categories.key?(params[:category])
      query = query.where(category: params[:category])
    end

    if (date_from = parse_filter_date(params[:date_from]))
      query = query.where("barangay_concerns.created_at >= ?", date_from.in_time_zone.beginning_of_day)
    end

    if (date_to = parse_filter_date(params[:date_to]))
      query = query.where("barangay_concerns.created_at <= ?", date_to.in_time_zone.end_of_day)
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

  def reports
    prepare_report_filters
    query = reports_query
    @report_count = query.count
    @pagy, @report_rows = pagy(:offset, query, items: 10)
  end

  def reports_export
    prepare_report_filters
    rows = reports_query

    csv_data = CSV.generate(headers: true) do |csv|
      csv << report_csv_headers
      rows.each { |record| csv << report_csv_row(record) }
    end
    csv_data.prepend("\uFEFF")

    send_data csv_data,
              filename: "ulat-#{@report_type}-#{@date_from}-hanggang-#{@date_to}.csv",
              type: "text/csv; charset=utf-8"
  end

  private
    def prepare_report_filters
      @report_type = %w[documents concerns residents].include?(params[:report]) ? params[:report] : "documents"
      @date_from = parse_filter_date(params[:date_from]) || Time.zone.today.beginning_of_month
      @date_to = parse_filter_date(params[:date_to]) || Time.zone.today
      @date_to = @date_from if @date_to < @date_from
    end

    def reports_query
      date_range = @date_from.beginning_of_day..@date_to.end_of_day

      case @report_type
      when "concerns"
        BarangayConcern.includes(resident: [:profile, :address])
                       .where(created_at: date_range).order(created_at: :desc)
      when "residents"
        HouseholdMember.joins(:household).includes(household: :household_members)
                       .where(households: { date_accomplished: @date_from..@date_to })
                       .order("households.date_accomplished DESC, households.id ASC, household_members.id ASC")
      else
        DocumentRequest.includes(resident: [:profile, :address])
                       .where(created_at: date_range).order(created_at: :desc)
      end
    end

    def report_csv_headers
      if @report_type == "residents"
        return ["Numero ng Sambahayan", "Apelyido", "Pangalan", "Gitnang Pangalan", "Dugtong sa Pangalan", "Purok", "Kalye / Subdibisyon", "Petsa ng Kapanganakan", "Kasarian", "Katayuang Sibil", "Pagkamamamayan", "Hanapbuhay"]
      end

      detail_header = @report_type == "documents" ? "Uri ng Dokumento" : (@report_type == "concerns" ? "Uri ng Suliranin" : "Uri ng Talaan")
      ["Sanggunian", "Petsa ng Pagtatala", "Pangalan ng Residente", "Purok / Tirahan", detail_header, @report_type == "residents" ? "Email" : "Layunin / Detalye", "Kalagayan"]
    end

    def report_csv_row(record)
      case @report_type
      when "residents"
        household = record.household
        household_number = "HH-#{household.date_accomplished.year}-#{household.id.to_s.rjust(4, '0')}"
        [household_number, record.last_name, record.first_name, record.middle_name, record.suffix,
         "Purok #{household.purok}", [household.house_number, household.street].compact_blank.join(", "),
         record.birth_date, view_context.tagalog_label(record.sex), view_context.tagalog_label(record.civil_status), record.citizenship, record.occupation]
      when "concerns"
        category = { "peace_and_order" => "Kapayapaan at Kaayusan", "infrastructure" => "Imprastraktura", "waste_management" => "Pamamahala ng Basura", "health_and_sanitation" => "Kalusugan at Kalinisan", "others" => "Iba pa" }[record.category]
        [record.tracking_number, record.created_at, report_resident_name(record.resident), report_address(record.resident&.address), category, record.reason, report_status_label(record.status)]
      else
        [record.tracking_number, record.created_at, report_resident_name(record.resident), report_address(record.resident&.address), record.document_type.humanize, record.purpose, report_status_label(record.status)]
      end
    end

    def report_status_label(status)
      { "pending" => "Naghihintay", "processing" => "Pinoproseso", "rejected" => "Tinanggihan", "ready_to_pickup" => "Inilabas", "claimed" => "Inilabas", "ongoing" => "Pinoproseso", "resolved" => "Nalutas", "unactionable" => "Hindi maaksyunan" }[status] || status
    end

    def report_resident_name(user)
      profile = user&.profile
      [profile&.first_name, profile&.middle_name, profile&.last_name, profile&.suffix].compact_blank.join(" ")
    end

    def report_address(address)
      return "" unless address

      [address.purok, address.house_number, address.street, address.barangay, address.city].compact_blank.join(", ")
    end

    def parse_filter_date(value)
      Date.iso8601(value) if value.present?
    rescue ArgumentError, TypeError
      nil
    end

    def authorize_staff!
      unless current_user.barangay_staff?
        redirect_to root_path, alert: "Unauthorized!"
      end
    end
end
