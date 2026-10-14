# backend/app/jobs/cleanup_old_tracked_jobs_job.rb
class CleanupOldTrackedJobsJob < ApplicationJob
  queue_as :low_priority

  def perform(days_to_keep: 30)
    purged_count = TrackedJob.cleanup_old_jobs!(retention_period: days_to_keep.days)
    Rails.logger.info("[Cleanup] Purged #{purged_count} records older than #{days_to_keep} days.")
  end
end