class CreateTrackedJobs < ActiveRecord::Migration[8.1]
 def change
    create_table :tracked_jobs do |t|
      t.string :linkedin_job_id, null: false
      t.string :title, null: false
      t.string :company
      t.string :location
      t.string :url, null: false
      t.datetime :posted_at
      t.boolean :notified, default: false, null: false
      t.boolean :saved, default: false, null: false
      t.boolean :applied, default: false, null: false

      t.timestamps
    end

    add_index :tracked_jobs, :linkedin_job_id, unique: true
    add_index :tracked_jobs, [:saved, :applied, :created_at]
  end
end
