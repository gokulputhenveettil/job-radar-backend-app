class AddDescriptionToTrackedJobs < ActiveRecord::Migration[8.1]
  def change
    add_column :tracked_jobs, :description, :text
  end
end
