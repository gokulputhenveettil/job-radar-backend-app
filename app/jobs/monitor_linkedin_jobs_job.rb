# backend/app/jobs/monitor_linkedin_jobs_job.rb
class MonitorLinkedinJobsJob < ApplicationJob
  queue_as :default

  def perform(recipient_email: "you@example.com", keywords: "Ruby on Rails", location: "Remote")
    scraped_jobs = LinkedinJobMonitor.new(keywords: keywords, location: location).fetch_recent_jobs
    return if scraped_jobs.empty?

    scraped_ids = scraped_jobs.map { |j| j[:linkedin_job_id] }
    existing_ids = TrackedJob.where(linkedin_job_id: scraped_ids).pluck(:linkedin_job_id)

    new_attributes = scraped_jobs.reject { |j| existing_ids.include?(j[:linkedin_job_id]) }
    return if new_attributes.empty?

    TrackedJob.insert_all(new_attributes)

    newly_saved = TrackedJob.where(linkedin_job_id: new_attributes.map { |j| j[:linkedin_job_id] })
    JobAlertMailer.new_jobs_email(recipient_email, newly_saved).deliver_now
    newly_saved.update_all(notified: true)
  end
end