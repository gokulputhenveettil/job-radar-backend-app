# backend/app/jobs/generate_cover_letter_job.rb
class GenerateCoverLetterJob < ApplicationJob
  queue_as :default

  def perform(job_id, format_type = "inmail")
    job = TrackedJob.find_by(id: job_id)
    return unless job

    # Fetch description if missing
    if job.description.blank?
      desc = LinkedinDescriptionFetcher.call(job.url)
      job.update!(description: desc) if desc.present?
    end

    # Generate outreach note via LLM
    content = CoverLetterGenerator.new(
      tracked_job: job,
      format_type: format_type
    ).call

    # Broadcast to the specific job channel
    ActionCable.server.broadcast("job_cover_letter_#{job.id}", {
      status: "completed",
      job_id: job.id,
      format_type: format_type,
      cover_letter: content
    })
  rescue StandardError => e
    Rails.logger.error("[GenerateCoverLetterJob] Failed for job #{job_id}: #{e.class}: #{e.message}")
    ActionCable.server.broadcast("job_cover_letter_#{job_id}", {
      status: "failed",
      job_id: job_id,
      format_type: format_type,
      error: e.message
    })
  end
end
