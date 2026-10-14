class AddDismissedToTrackedJobs < ActiveRecord::Migration[8.1]
  def change
    add_column :tracked_jobs, :dismissed, :boolean, default: false, null: false
    add_index :tracked_jobs, :dismissed
  end
end
