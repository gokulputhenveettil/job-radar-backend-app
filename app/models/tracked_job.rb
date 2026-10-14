# backend/app/models/tracked_job.rb
class TrackedJob < ApplicationRecord
  validates :linkedin_job_id, presence: true, uniqueness: true
  validates :title, :url, presence: true

  # Default active feed excludes dismissed postings
  scope :active, -> { where(dismissed: false) }
  scope :recent, -> { active.order(created_at: :desc) }

  scope :saved_jobs, -> { active.where(saved: true) }
  scope :applied_jobs, -> { active.where(applied: true) }
  scope :unapplied_jobs, -> { active.where(applied: false) }

  # Retention cleanup: purge jobs older than threshold UNLESS saved or applied
  # Keep dismissed jobs around until the retention threshold so they aren't re-scraped
  scope :purgeable, ->(cutoff = 30.days.ago) {
    where(saved: false, applied: false).where("created_at < ?", cutoff)
  }

  def self.cleanup_old_jobs!(retention_period: 30.days)
    purgeable(retention_period.ago).in_batches(of: 1_000).destroy_all
  end
end
