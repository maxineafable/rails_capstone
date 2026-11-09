class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def mark_all_read
    current_user.resident_notifications.unread.update_all(read_at: Time.current)
    head :no_content
  end

  def destroy
    current_user.resident_notifications.find(params[:id]).destroy!
    render json: inbox_counts
  end

  def destroy_all
    current_user.resident_notifications.destroy_all
    render json: inbox_counts
  end

  private

  def inbox_counts
    {
      remaining_count: current_user.resident_notifications.count,
      unread_count: current_user.resident_notifications.unread.count
    }
  end
end
