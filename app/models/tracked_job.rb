# backend/app/models/tracked_job.rb
class TrackedJob < ApplicationRecord
  has_many :user_tracked_jobs, dependent: :destroy
  has_many :users, through: :user_tracked_jobs

  validates :linkedin_job_id, presence: true, uniqueness: true
  validates :title, :url, presence: true

  scope :recent, -> { order(created_at: :desc) }

  # Retain old jobs while any user has saved or applied them.
  scope :purgeable, ->(cutoff = 30.days.ago) {
    where.not(
      id: UserTrackedJob.where(saved: true)
        .or(UserTrackedJob.where(applied: true))
        .select(:tracked_job_id)
    ).where("created_at < ?", cutoff)
  }

  def self.cleanup_old_jobs!(retention_period: 30.days)
    purgeable(retention_period.ago).in_batches(of: 1_000).destroy_all
  end
end
