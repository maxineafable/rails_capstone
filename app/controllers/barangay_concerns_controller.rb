class BarangayConcernsController < ApplicationController
  before_action :authenticate_user!

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

  private
    def barangay_concern_params
      params.require(:barangay_concern).permit(:category, :reason, :resident_remarks, :evidence_image)
    end
end
