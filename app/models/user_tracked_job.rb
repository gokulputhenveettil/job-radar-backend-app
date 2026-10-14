class UserTrackedJob < ApplicationRecord
  belongs_to :user
  belongs_to :tracked_job

  validates :tracked_job_id, uniqueness: { scope: :user_id }
end
