# backend/app/channels/cover_letter_channel.rb
class CoverLetterChannel < ApplicationCable::Channel
  def subscribed
    stream_from "job_cover_letter_#{params[:job_id]}"
  end

  def unsubscribed
    stop_all_streams
  end
end
